# Decisions

Plain record of architectural and implementation decisions made in this project: what was decided, why, what alternatives were considered, and what real deployment issues shaped the final design. Organized by theme rather than chronologically.

## Architecture

**Topology: native VNet peering hub-and-spoke, not Azure Virtual WAN.** At 3 subscriptions / 3 VNets, Virtual WAN's managed routing and hub-unit cost add no capability over native peering. Native peering also forces explicit UDR/NSG configuration rather than abstracting routing behind a managed control plane, which better demonstrates understanding of the underlying primitives. Virtual WAN is the correct choice at a larger scale (dozens of VNets, multi-region, branch/VPN connectivity) - not at this scale.

**Firewall SKU: Standard, not Basic or Premium.** Basic SKU's threat intelligence is alert-only (logs but does not block malicious traffic), inconsistent with a zero-trust design. Premium's TLS inspection and IDPS solve a problem this project doesn't have and carry materially higher cost. Standard supports full threat intelligence in Deny mode, DNS proxy, and custom DNS at a lower fixed cost than Premium.

**Threat intelligence mode: Deny.** Threat intelligence matches known-malicious infrastructure specifically, not general traffic patterns - risk of a false positive blocking legitimate traffic is low. Alert-then-tune is the correct pattern for a production rollout against unknown, high-volume real traffic over weeks; not needed for this project. Deny is the production-correct setting and consistent with the project's zero-trust posture. (Initial draft used Alert out of excess caution; corrected after reviewing what threat intelligence actually matches against.)

**Bastion SKU: Standard, not Basic or Premium.** Standard supports native client tunneling (`tunneling_enabled`), which is what allows native SSH/RDP clients to connect without any public port on the target VM - the specific mechanism that makes "zero public management ports" true in practice, validated directly (see Validation Evidence in README). Premium's session recording was not used; session activity is captured via `BastionAuditLogs` diagnostic logs instead - connection auditing (who connected, when, to what), not full session recording (keystrokes/video).

**Firewall Policy as a separate resource from the Firewall.** `azurerm_firewall_policy` + `firewall_policy_id` is the current Azure-recommended pattern, required for Firewall Manager integration, rule inheritance across multiple firewalls, and Premium features.

**Explicit default-deny rule collection group and NSG rule.** Azure Firewall and NSGs already deny non-matching/non-allowed traffic by default. Explicit deny-all rules were added anyway to make the zero-trust posture visible and auditable in code rather than relying on an invisible platform default - and this default-deny baseline was directly validated: real traffic (background VM telemetry, deliberate spoke-to-spoke test traffic) was confirmed denied and logged during testing.

## Traffic control mechanics

**Forced tunneling via UDR, not reliance on peering alone.** VNet peering does not force traffic through the firewall by default. Route tables with `0.0.0.0/0` routes (`next_hop_type = VirtualAppliance`, next hop = firewall private IP) are applied to every subnet in each spoke, with `bgp_route_propagation_enabled = false` to prevent a future VPN/ExpressRoute gateway from injecting a competing route. Validated via `az network nic show-effective-route-table` against a real deployed VM.

**`allow_forwarded_traffic = true` on all peering connections.** Required on both hub-to-spoke and spoke-to-hub peering legs. Without it, traffic arriving at a VNet with a destination other than that VNet itself is silently dropped, even though the peering connection itself shows as "Connected."

**Intra-VNet traffic (subnet-to-subnet within the same spoke) does not traverse the firewall.** Azure's system route for the VNet's own address space is more specific than the `0.0.0.0/0` UDR and always wins on longest-prefix match. NSGs are therefore the *only* enforcement point for intra-VNet traffic, not a backup to firewall inspection - a distinction worth being precise about rather than overclaiming full-mesh firewall inspection.

**Ingress (internet-to-workload) is out of scope for this project.** UDRs only govern egress; they have no effect on how traffic arrives. Getting inbound traffic under zero-trust control requires a separate mechanism (Firewall DNAT rules or a reverse proxy such as Application Gateway) sitting in the traffic's actual path before reaching the workload - not built here, since no workload requiring inbound access exists yet.

**Bastion-to-VM traffic bypasses the firewall by design, not by gap.** VNet peering creates a system route for the entire peered hub address space, more specific than the `0.0.0.0/0` UDR - Bastion traffic travels directly over the peering link. This is standard, expected hub-and-spoke behavior: Bastion is itself the access-control and audit layer for management traffic, not a workload needing firewall inspection on top of it. `BastionAuditLogs` is the visibility mechanism for this specific traffic path, not Firewall logs.

**`private_endpoint_network_policies = "Enabled"` on private endpoint subnets.** Without this, private endpoints historically bypass NSG and route table enforcement on their subnet.

## Addressing and forward planning

**IP addressing: `10.0.0.0/8` reserved as one supernet, allocated per environment as `/16`s.** Prevents CIDR collisions across current and future (AKS, DR) projects without needing to audit existing deployments each time a new project starts.

**AKS node subnets: provisioned now, not deferred.** Initially scoped to reserve the CIDR as a variable only. Revised: the subnet, route table association, and a dedicated baseline NSG are provisioned instead, so a future AKS deployment can go directly into an existing, already-integrated (forced-tunneling, logged) subnet with no networking work left to do. Firewall application/FQDN allow-rules for AKS control plane traffic (MCR, Entra ID, `*.hcp.<region>.azmk8s.io`, etc.) remain explicitly out of scope here, since those rules are workload-specific and cannot be written correctly before a cluster exists.

**Azure CNI Overlay selected for the future AKS project.** Keeps pod IP consumption out of VNet address space entirely - the AKS node subnet reservations are sized for node count plus upgrade-surge headroom only, not pod count.

**Monitoring private endpoints (AMPLS): scoped out of this phase.** A `/28` is reserved within the hub's shared-services subnet for future Azure Monitor Private Link Scope private endpoints. Log Analytics currently uses public ingestion/query endpoints. Deliberate sequencing: validate the core network architecture first, close the monitoring-plane privacy gap as a follow-up.

## Observability

**Centralized Log Analytics workspace, built ahead of the dedicated Observability project.** Firewall and Bastion diagnostics ship to one shared workspace starting with this project, so the future Observability project inherits real historical data instead of starting cold.

**Log Analytics workspace: dedicated resource group, separate from hub's.** Hub's diagnostic settings require the workspace's `workspace_id` output (log_analytics must be created first); if log_analytics deployed into hub's resource group, it would require hub's resource group to exist first - an unresolvable circular dependency. A separate resource group breaks the cycle and is architecturally reasonable regardless: Log Analytics is shared infrastructure consumed by hub and both spokes, not owned by hub specifically.

**VNet flow logs: raw storage only, Traffic Analytics disabled.** Traffic Analytics enablement is blocked by the Landing Zone's `baseline-platform` governance policy (`TARequestDisallowedByPolicy`). Root cause identified precisely: enabling Traffic Analytics triggers Azure to auto-provision a hidden `Microsoft.OperationsManagement/solutions` resource inside the workspace's resource group, created without tags - the `Require a tag on resources` policy correctly denies it, and no tag added to project-managed resources can fix this, since the untagged resource is never one this project controls. Flow logs still write raw JSON to the per-spoke storage account and remain queryable directly.

**VNet-scoped flow logs, not NSG-scoped.** Azure deprecated creation of new NSG-scoped flow logs (`network_security_group_id`) as of July 30, 2025. VNet-scoped flow logs (`target_resource_id`) cover every subnet in one resource instead of requiring a new flow log per NSG added later.

**Bastion audit logs land in a dedicated table (`MicrosoftAzureBastionAuditLogs`), not the shared `AzureDiagnostics` table.** Discovered during validation: despite the diagnostic setting correctly showing `BastionAuditLogs` enabled and routed to the workspace, querying `AzureDiagnostics` returned zero results across multiple confirmed successful sessions (both CLI native-client and Portal-based). Checking the workspace's Tables blade directly surfaced the correct table. Not every Azure resource type routes into the legacy shared table - worth checking Tables directly whenever a diagnostic setting appears correctly configured but expected data isn't showing up where anticipated.

**`enabled_metric` used instead of deprecated `metric` block.** `metric` in `azurerm_monitor_diagnostic_setting` is deprecated in AzureRM provider ~4.81+, scheduled for removal in v5.0.

## Terraform architecture

**Module structure: `hub`, `spoke`, `peering`, `log-analytics` as separate modules.** Production and NonProd spokes are structurally identical and differ only in CIDR/tag values - the `spoke` module is called twice rather than duplicating resource blocks.

**Provider aliasing: three subscription-scoped `azurerm` providers in one root module.** The `azurerm` provider is scoped to one subscription per block; hub and spokes span three subscriptions. A single root module with three aliased providers was chosen over three independent root configs, because hub-and-spoke is one interconnected system with cross-referencing values (firewall private IP consumed by spoke route tables).

**Peering module: `configuration_aliases` for dual-subscription resources within one module.** The peering module creates two resources (hub-to-spoke, spoke-to-hub) in two different subscriptions. `configuration_aliases = [azurerm.hub, azurerm.spoke]` lets the module declare it needs two provider configurations simultaneously; the caller maps the actual subscription providers via `providers = {}`. Note: `configuration_aliases` belongs only in the *child* module receiving extra providers, never in the root - the root has no caller, so declaring it there produces an unresolvable "root module requires the caller" error (encountered and corrected during this build).

**Remote state: reuse existing storage account, new state file key.** State lives in the same `omotayotfstate` storage account used by the Landing Zone project, under a new blob key - avoids creating a new state storage account for every project sharing the same backend.

**`resource_provider_registrations = "core"` set explicitly.** AzureRM provider v4.x defaults to `"legacy"` resource provider registration behavior; set explicitly following a real issue encountered in the Landing Zone project.

## Real deployment issues encountered and resolved

Deploying against a live, governed multi-subscription environment (not just `terraform plan` in isolation) surfaced genuine issues beyond syntax - each is a real finding, not a hypothetical:

**Required-tag policy blocked initial `apply`.** The Landing Zone's `baseline-platform` policy assignment (built-in "Require a tag on resources") rejected the hub VNet outright. Root cause: `project_tags` didn't include the tag key the policy actually requires. Fixed by adding the correct key/value to the shared tag map, which every module consumes.

**Allowed-SKUs policy blocked default VM sizing.** Validation test VMs failed with `RequestDisallowedByPolicy` when no `--size` was specified (Azure's implicit default SKU wasn't on the policy's allow-list). Fixed by specifying an explicitly allowed size.

**Azure CLI subcommand gaps in `--tags` support.** `az resource create` and certain `az network` subcommands do not reliably support `--tags` for every resource type (a known, tracked Azure CLI limitation, not specific to this project) - creating a tag-policy-compliant Network Watcher via CLI required falling back to `az deployment group create` with an inline ARM template, which has full, unambiguous support for `tags` regardless of CLI-level gaps.

**Network Watcher: Terraform-managed, not assumed pre-existing.** Initial implementation assumed `NetworkWatcherRG`/`NetworkWatcher_<region>` already existed (Azure auto-creates these when certain actions happen via the Portal). This proved false for subscriptions provisioned and operated purely through Terraform/CLI. Resolved by having the spoke module create both the resource group and the Network Watcher resource directly, so `apply` is fully self-contained.

**Resource group propagation delay caused intermittent `ResourceGroupNotFound`.** Creating a VNet immediately after its resource group occasionally 404'd even though Terraform's dependency ordering was correct - a real Azure Resource Manager control-plane propagation delay, confirmed by the same `apply` succeeding on retry. Fixed with an explicit `time_sleep` (30s) between resource group creation and dependent resources - HashiCorp's documented workaround for this class of timing issue.

**Peering creation failed with `ReferencedResourceNotProvisioned` while a spoke's subnets were still provisioning.** Terraform's implicit dependency on a spoke module's `vnet_id` output only guarantees the VNet resource exists, not that every subnet inside it has finished - subnets are separate operations that can still be in flight. Fixed with explicit `depends_on = [module.spoke_production]` (and NonProd equivalent) at the peering module calls, forcing Terraform to wait for the entire module, not just one output value.

**Bastion subnet deletion failed with `InUseSubnetCannotBeDeleted` during a `destroy`/replace.** The referenced resource was in a hidden, Microsoft-managed resource group (`ARMRG-...`) in a different subscription entirely - Bastion's own backend VM scale set. This is expected: Bastion teardown isn't instantaneous, and a subnet delete attempted immediately after can race the backend cleanup. Resolved by retrying after the backend finished tearing down; no code-level fix exists for this specific timing window beyond patience, since it happens after the customer-facing resource is already gone.

