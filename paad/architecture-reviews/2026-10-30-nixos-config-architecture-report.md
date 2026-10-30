# Architecture Report — nixos-config

* **Date:** 2026-10-30
* **Model:** openai-codex/gpt-6-sol
* **PAAD version:** 2.0.2
* **Commit:** 52bae23d92f259ddc227a203148ed955648cbb00
* **Languages:** Nix, shell, Lua; NixOS, Home Manager, System Manager
* **Key directories:** `hosts/`, `modules/`, `home/fernando/`, `standalone-system/`, `.tack/`
* **Scope:** full repository

## Repo Overview

This repository declares a NixOS VM and mini-PC, standalone Linux/macOS Home Manager profiles, and an Ubuntu/Fedora graphical-login profile. Its 58 tracked Nix/shell/Lua source files are composed from host entry points, shared system modules, platform-specific user modules, and a separate System Manager entry point. Tack pins the external inputs; this is host configuration, not an application with distributed service APIs or shared databases.

## Strengths

### [S1] System and user profiles have explicit composition boundaries
- **Category:** S1 Clear modular boundaries
- **Impact:** Low
- **Explanation:** Shared system concerns are composed by one NixOS module, while Home Manager selects common, Linux desktop, and Darwin modules conditionally. The profiles can differ without duplicating the whole entry-point graph.
- **Evidence:** `modules/default.nix:3-13` (`imports`), excerpt: `./desktop ... ./home-manager.nix ... ./users.nix`; `home/fernando/default.nix:3-14` (`imports`), excerpt: `lib.optionals (homePlatform == "linux" && homeDesktop) [ ./linux-desktop.nix ]`.
- **Found by:** StructureBoundaries

### [S2] External package sets use explicit shared pinning
- **Category:** S5 Dependency management hygiene
- **Impact:** Low
- **Explanation:** Tack declares the Home Manager input and makes its Nixpkgs dependency follow the repository's Nixpkgs input, rather than independently selecting a second package set.
- **Evidence:** `.tack/pins.toml:56-58` (`inputs.home-manager`), excerpt: `follows = { nixpkgs = "nixpkgs" }`.
- **Found by:** CouplingDependencies

### [S3] Portal ownership is conditional on deployment mode
- **Category:** S3 Loose coupling
- **Impact:** Low
- **Explanation:** Standalone Home Manager supplies the portal packages, whereas the integrated NixOS profile leaves portal ownership to the system module. The choice is explicit at the platform boundary.
- **Evidence:** `home/fernando/desktop/niri.nix:5-13` (`wayland.windowManager.niri`, `xdg.portal.extraPortals`), excerpt: `portalPackage = if standalone then pkgs.xdg-desktop-portal-gnome else null;`.
- **Found by:** CouplingDependencies

### [S4] Session startup fails explicitly on missing prerequisites
- **Category:** S7 Robust error handling
- **Impact:** Low
- **Explanation:** The standalone session launcher checks both `HOME` and the expected Home Manager executable, emits a diagnostic, and exits before attempting a broken session.
- **Evidence:** `standalone-system/default.nix:10-19` (`sessionPackage` launcher), excerpt: `if [ ! -x "$launcher" ]; then ... exit 1`.
- **Found by:** ErrorObservability

6 security finding(s) written to paad/security/agentic-architecture-2026-10-30-nixos-config.md

## Flaws/Risks

### [F1] Effective Noctalia settings can differ from checked-in declarations
- **Category:** 22 Configuration sprawl
- **Impact:** Low
- **Explanation:** Nix defaults are merged with a checked-in TOML snapshot, while the application can persist UI changes in a state-directory file that overrides generated settings. The precedence is documented, but effective preferences are not necessarily recoverable from the repository alone.
- **Evidence:** `home/fernando/desktop/noctalia.nix:14-35` (`programs.noctalia.settings`), excerpt: `lib.recursiveUpdate { ... } (lib.optionalAttrs isMinipc (builtins.fromTOML (builtins.readFile ./noctalia-settings.toml)))`; `docs/research/noctalia-plugins.md:32` (state precedence), excerpt: `sidecar values override the Nix-generated file`.
- **Found by:** StructureBoundaries, ErrorObservability (overlapping Nix/TOML and state-precedence findings)

3 security finding(s) written to paad/security/agentic-architecture-2026-10-30-nixos-config.md

## Coverage Checklist

Statuses count this report's findings only; routed findings are in the security file's checklist.

### Flaw/Risk Types 1–34
| # | Type | Status | Finding |
|---|------|--------|---------|
| 1 | Global mutable state | Not observed | — |
| 2 | God object | Not observed | — |
| 3 | Tight coupling | Not observed | — |
| 4 | High/unstable dependencies | Not observed | — |
| 5 | Circular dependencies | Not observed | — |
| 6 | Leaky abstractions | Not observed | — |
| 7 | Over-abstraction | Not observed | — |
| 8 | Premature optimization | Not observed | — |
| 9 | Shotgun surgery | Not observed | — |
| 10 | Feature envy / anemic domain model | Not applicable | Declarative host configuration |
| 11 | Low cohesion | Not observed | — |
| 12 | Hidden side effects | Not observed | — |
| 13 | Inconsistent boundaries | Not observed | — |
| 14 | Distributed monolith | Not applicable | No distributed application |
| 15 | Chatty service calls | Not applicable | No application service-call chain |
| 16 | Synchronous-only integration | Not applicable | No distributed application workflow |
| 17 | No clear ownership of data | Not observed | — |
| 18 | Shared database across services | Not applicable | No shared database |
| 19 | Lack of idempotency | Not applicable | No distributed retry operation |
| 20 | Weak error handling strategy | Not observed | — |
| 21 | No observability plan | Not observed | — |
| 22 | Configuration sprawl | Observed | #F1 |
| 23 | Dependency injection misuse | Not applicable | No DI container |
| 24 | Inconsistent API contracts | Not applicable | No application API |
| 25 | Business logic in the UI | Not applicable | Configuration, not app UI logic |
| 26 | Poor transactional boundaries | Not applicable | No cross-service transaction |
| 27 | Temporal coupling | Not observed | — |
| 28 | Magic numbers/strings everywhere | Not observed | — |
| 29 | Utility dumping ground | Not observed | — |
| 30 | Security as an afterthought | See security file | see paad/security/ |
| 31 | Dead code / unused dependencies | Not observed | — |
| 32 | Missing or inadequate test coverage for critical paths | Not observed | — |
| 33 | Hard-coded credentials or secrets in source | See security file | see paad/security/ |
| 34 | Inconsistent error/logging conventions | Not observed | — |

### Strength Categories S1–S14
| # | Category | Status | Finding |
|---|----------|--------|---------|
| S1 | Clear modular boundaries | Observed | #S1 |
| S2 | High cohesion | Not observed | — |
| S3 | Loose coupling | Observed | #S3 |
| S4 | Dependency direction is stable | Not observed | — |
| S5 | Dependency management hygiene | Observed | #S2 |
| S6 | Consistent API contracts | Not applicable | No application API |
| S7 | Robust error handling | Observed | #S4 |
| S8 | Observability present | Not observed | — |
| S9 | Configuration discipline | Not observed | — |
| S10 | Security built-in | See security file | see paad/security/ |
| S11 | Testability & coverage | Not observed | — |
| S12 | Resilience patterns | Not observed | — |
| S13 | Domain modeling strength | Not applicable | Declarative host configuration |
| S14 | Simple, pragmatic abstractions | Not observed | — |

## Hotspots

1. `home/fernando/desktop/noctalia.nix` — generated preferences and persisted application preferences have different precedence.
2. `home/fernando/desktop/noctalia-settings.toml` — a second checked-in representation supplies host-specific desktop settings.
3. `standalone-system/default.nix` — session startup explicitly depends on the user profile being present.

## Next Questions

1. Which Noctalia preferences currently exist in the state-directory override on activated desktops?
2. How often do desktop preferences change through the UI rather than the checked-in snapshot?
3. Are the standalone session's Home Manager prerequisites reliably present before graphical login is enabled?

## Analysis Metadata

- **Agents dispatched:** StructureBoundaries (module organization), CouplingDependencies (dependency direction), IntegrationData (service integration), ErrorObservability (error/config/operations), SecurityQuality (security/coverage); ArchitectureVerifier (verification)
- **Scope:** full repo, 58 tracked Nix/shell/Lua source files plus settings, pin manifest, README, and research documentation
- **Raw findings:** 29 (before verification)
- **Verified findings:** 14 (after verification and deduplication)
- **Filtered out:** 15
- **By impact:** 0 high, 0 medium, 5 low (this report's findings only)
- **Security:** 9 finding(s) written to paad/security/agentic-architecture-2026-10-30-nixos-config.md
- **Steering files consulted:** none found
