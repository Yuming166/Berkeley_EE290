Cellular Communication System Modeling under Mobility

<p align="center">
  <b>Yuming Gao </b><br>
  University of California, Berkeley
</p>
<p align="center">
  A MATLAB-based system-level simulation study of cellular connectivity under high user mobility.
</p>
<p align="center">
  <img src="https://img.shields.io/badge/MATLAB-R2025a%2B-orange" alt="MATLAB">
  <img src="https://img.shields.io/badge/5G-NR-blue" alt="5G NR">
  <img src="https://img.shields.io/badge/Topic-Wireless%20Networks-green" alt="Wireless Networks">
</p>

⸻

Overview

This project develops a MATLAB-based system-level simulation framework for evaluating cellular connectivity under high user mobility.

The study investigates how mobility, Doppler-induced channel variation, heterogeneous cellular deployments, and antenna configurations affect wireless link performance and reliability.

The main performance metrics are:

* Signal-to-Interference-plus-Noise Ratio (SINR)
* Throughput
* Handover frequency
* Radio Link Failure (RLF)
* SISO/MIMO performance
* Monte Carlo performance statistics

The implementation progressively extends a baseline cellular model toward more realistic time-varying and MIMO channel models.

⸻

Project Information

	
Author	Yuming Gao
Course	EE290 — Wireless Networks
Institution	University of California, Berkeley
Instructor	Shyam Parekh
Project Period	Aug 2025 – Nov 2025
Language	MATLAB
Toolboxes	MATLAB 5G Toolbox (for CDL simulation)

⸻

Technical Approach

The project follows a progressive modeling framework:

┌──────────────────────────────┐
│   Baseline Cellular Model    │
│ Path Loss + Shadowing +      │
│ Rayleigh Fading              │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│    Doppler-Aware Model       │
│ Time-Correlated Fading       │
│ Mobility-Dependent Channel   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│    Monte Carlo Evaluation    │
│ Multiple Channel Realizations│
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│    SISO / MIMO Modeling      │
│       1×2 / 2×2 MIMO        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│     5G NR CDL Channel        │
│     CDL-D / 1×2 MIMO        │
└──────────────────────────────┘

This structure allows the impact of increasingly realistic channel and antenna models to be evaluated while maintaining a consistent set of system-level performance metrics.

⸻

System Model

The simulations model a mobile user moving through a heterogeneous cellular network.

Representative Parameters

Parameter	Setting
Carrier frequency	3.5 GHz
Bandwidth	10 MHz
UE velocity	30 / 90 / 150 mph
Simulation duration	20 s
Time step	10 ms
Small-scale fading	Rayleigh
Shadowing	Log-normal
Mobility effect	Doppler
Antenna configurations	SISO / 1×2 / 2×2
Deployment	Macro / Macro + Small / Dense Small
Metrics	SINR / Throughput / HO / RLF

⸻

Channel Modeling

Path Loss

Distance-dependent path loss is used to model large-scale signal attenuation as the user moves through the cellular deployment.

Shadowing

Log-normal shadowing models slower variations in received signal power caused by environmental obstructions and propagation conditions.

Rayleigh Fading

Rayleigh fading models multipath-induced small-scale variations in the received signal.

Doppler Effect

For a mobile user with velocity (v), the maximum Doppler frequency is approximated by

[
f_D = \frac{v}{\lambda}
= \frac{v f_c}{c},
]

where:

* (v) is the UE velocity,
* (f_c) is the carrier frequency,
* (c) is the speed of light,
* (\lambda) is the carrier wavelength.

The Doppler frequency is used to control the temporal variation of the simulated fading process.

The Doppler-aware implementation uses Doppler-dependent filtering to approximate time-correlated small-scale fading.

⸻

Cellular Mobility and Connectivity

The serving cell is selected according to simulated received-link conditions.

As the UE moves through the network, changes in the strongest serving cell result in handover events.

The overall connectivity process can be summarized as:

UE Mobility
     │
     ▼
Channel Variation
     │
     ▼
Received Signal + Interference
     │
     ▼
     SINR
     │
     ├──────────────┐
     ▼              ▼
Throughput       Cell Selection
                      │
                      ▼
                   Handover
                      │
                      ▼
                    RLF

This allows the simulation to study the interaction between mobility, channel variation, handover behavior, and link reliability.

⸻

Performance Metrics

SINR

The signal-to-interference-plus-noise ratio is calculated as

[
\mathrm{SINR}

\frac{P_{\mathrm{signal}}}
{P_{\mathrm{interference}} + P_{\mathrm{noise}}}.
]

SINR is used as the primary instantaneous link-quality metric.

Throughput

A Shannon-capacity approximation is used to estimate achievable throughput:

[
R = B\log_2(1+\mathrm{SINR}),
]

where (B) denotes the system bandwidth.

Handover

A change in the serving cell is recorded as a handover event.

Handover frequency is used to characterize the mobility-management behavior of different cellular deployments.

Radio Link Failure

An RLF event occurs when the simulated SINR remains below a configured threshold for longer than the specified timeout.

RLF provides a system-level measure of connectivity reliability under adverse mobility conditions.

⸻

SISO and MIMO

The project evaluates multiple antenna configurations.

SISO

A single-input single-output configuration is used as the reference system.

1×2 MIMO

A 1×2 configuration is evaluated using a 5G NR CDL channel model, providing explicit receive-side spatial diversity.

2×2 MIMO

A 2×2 configuration is evaluated using Monte Carlo channel realizations to investigate the effect of multiple transmit and receive antennas.

Modeling note: The baseline implementation uses a simplified MIMO link-budget gain, while the later MIMO implementations explicitly model transmit/receive antenna configurations. These should therefore be interpreted as different levels of modeling fidelity rather than identical MIMO models.

⸻

5G NR CDL Channel Extension

The repository includes a higher-fidelity channel implementation using the MATLAB 5G Toolbox.

The mobility_cdL_1x2_MIMO.m simulation uses a Clustered Delay Line (CDL-D) channel model.

The model incorporates:

* Multipath propagation
* Delay spread
* Doppler effects
* Time-varying fading
* Multiple receive antennas
* High-mobility channel variation

This provides a more detailed representation of time-varying wireless propagation than the simplified Rayleigh fading models used in the earlier system-level simulations.

⸻

Monte Carlo Evaluation

Selected experiments use Monte Carlo channel realizations to reduce sensitivity to individual fading trajectories.

Instead of relying on a single realization, repeated channel simulations are used to characterize the distribution of system-level performance.

Representative outputs include:

* Mean SINR
* SINR distribution
* Mean throughput
* Throughput distribution
* Handover frequency
* RLF probability

This framework is particularly useful for comparing SISO and MIMO systems under different mobility conditions.

⸻

Repository Structure

Berkeley_EE290/
│
├── README.md
│
├── src/
│   ├── README.md
│   │
│   ├── baseline/
│   │   └── mobility_cell_eval.m
│   │
│   ├── doppler/
│   │   └── mobility_cell_eval_doppler.m
│   │
│   └── mimo/
│       ├── mobility_cell_eval_mc_MIMO.m
│       ├── mobility_SISO.m
│       └── mobility_cdL_1x2_MIMO.m
│
├── results/
│   ├── figures/
│   └── csv/
│
├── docs/
│   └── methodology.md
│
├── LICENSE
│
└── .gitignore

Directory Description

Directory	Description
src/baseline/	Baseline system-level cellular simulation
src/doppler/	Doppler-aware mobility and fading model
src/mimo/	SISO, 2×2 MIMO, and CDL channel simulations
results/figures/	Selected simulation figures
results/csv/	Numerical simulation results
docs/	Additional methodology and technical documentation

⸻

Simulation Workflow

A typical simulation follows the pipeline:

1. Define system parameters
          ↓
2. Generate cellular deployment
          ↓
3. Generate UE mobility trajectory
          ↓
4. Calculate path loss
          ↓
5. Apply shadowing
          ↓
6. Generate small-scale fading
          ↓
7. Apply Doppler-dependent channel variation
          ↓
8. Calculate received signal and interference
          ↓
9. Calculate SINR
          ↓
10. Estimate throughput
          ↓
11. Update serving cell
          ↓
12. Detect handover / RLF events
          ↓
13. Aggregate performance statistics

⸻

Running the Simulations

Run the scripts from MATLAB after adding the repository to the MATLAB path.

Baseline

cd src/baseline
mobility_cell_eval

Doppler-Aware Model

cd src/doppler
mobility_cell_eval_doppler

Monte Carlo MIMO

cd src/mimo
mobility_cell_eval_mc_MIMO

SISO Reference

cd src/mimo
mobility_SISO

5G NR CDL

cd src/mimo
mobility_cdL_1x2_MIMO

The CDL implementation requires the MATLAB 5G Toolbox.

⸻

Results

Selected simulation results are stored in results/figures/.

The experiments focus on four main comparisons.

1. Impact of Mobility

Higher UE velocity increases the maximum Doppler frequency and accelerates temporal channel variation.

This allows the effect of mobility on SINR, throughput, and connectivity reliability to be evaluated.

2. Impact of Deployment Density

Small-cell deployment can improve local link quality while introducing additional cell transitions.

The simulations therefore examine the trade-off between improved coverage and increased handover activity.

3. SISO vs. MIMO

Different antenna configurations are evaluated to investigate the benefits of spatial diversity under time-varying fading.

4. Connectivity Reliability

Handover and RLF statistics are evaluated together with SINR and throughput to provide a more complete view of cellular connectivity.

⸻

Key Takeaways

The simulations highlight several system-level relationships:

* Higher mobility → stronger Doppler effects → faster channel variation.
* Rapid channel variation can reduce link stability even when average received power remains relatively strong.
* Network densification can improve local link quality while increasing handover activity.
* MIMO provides additional spatial degrees of freedom that can improve robustness under fading.
* SINR, throughput, handover, and RLF should be considered jointly when evaluating cellular connectivity under mobility.

⸻

Modeling Scope

This project focuses on system-level modeling and comparative simulation, rather than full physical-layer 3GPP-compliant link-level simulation.

The simplified models use analytical propagation and fading models to study the relationship between mobility and cellular performance.

The CDL implementation provides a higher-fidelity 5G NR channel model for selected experiments.

The repository intentionally includes multiple modeling levels:

Model	Fidelity
Baseline cellular model	System-level
Doppler-aware Rayleigh model	Time-varying system-level
Monte Carlo MIMO	Statistical system-level
1×2 CDL-D	Higher-fidelity 5G NR channel

This makes it possible to study the same mobility problem under progressively more realistic channel assumptions.

⸻

Course Context

This project was completed for EE290 — Wireless Networks at the University of California, Berkeley.

The project applies concepts from:

* Wireless communication
* Cellular networks
* Wireless channel modeling
* Doppler effects
* Fading channels
* MIMO systems
* Mobility management
* Handover
* Radio Link Failure
* 5G NR channel modeling

Project Credits

Author: Yuming Gao
Instructor: Shyam Parekh
Institution: University of California, Berkeley
Course: EE290 — Wireless Networks
Period: August 2025 – November 2025

⸻

License

This repository is intended primarily for educational and research demonstration purposes.

See LICENSE for details.
