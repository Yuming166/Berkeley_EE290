Methodology

This document describes the system-level modeling methodology used in the Cellular Communication System Modeling under Mobility project.

The simulation framework progressively incorporates propagation loss, shadowing, small-scale fading, mobility-induced Doppler effects, cellular association, handover, radio link failure, and SISO/MIMO configurations.

⸻

1. System Model

The system consists of multiple base stations and a mobile user equipment (UE).

The UE moves through the cellular deployment at a specified velocity while the received signal power varies according to:

1. UE-to-base-station distance
2. Path loss
3. Shadowing
4. Small-scale fading
5. Doppler-induced temporal variation

At each simulation time step, the received signal power from each candidate cell is evaluated.

The serving cell is then selected according to the simulated link conditions.

The overall simulation can be represented as

UE Mobility
     │
     ▼
Distance to Base Stations
     │
     ▼
Path Loss
     │
     ├──────► Shadowing
     │
     └──────► Small-Scale Fading
                    │
                    ▼
              Doppler Variation
                    │
                    ▼
          Received Signal Power
                    │
                    ▼
                   SINR
              ┌─────┴─────┐
              ▼           ▼
         Throughput    Cell Selection
                           │
                           ▼
                        Handover
                           │
                           ▼
                          RLF

⸻

2. Simulation Parameters

The representative simulation configuration is summarized below.

Parameter	Value
Carrier frequency	3.5 GHz
Bandwidth	10 MHz
Noise figure	7 dB
Simulation duration	20 s
Time step	0.01 s
UE velocity	30 / 90 / 150 mph
Macro shadowing standard deviation	12 dB
Small-cell shadowing standard deviation	14 dB
MIMO gain in baseline model	3 dB
RLF timeout	0.2 s

Some parameters may vary between exploratory simulation scripts. The values above describe the primary system-level configuration.

⸻

3. Mobility Model

The UE follows a deterministic trajectory through the cellular deployment.

For a simulation time (t), the UE position is represented by

$$
\mathbf{p}(t) =
\begin{bmatrix}
x(t) \
y(t)
\end{bmatrix}.
$$

The UE velocity is specified in miles per hour and converted to SI units before calculating propagation and Doppler effects.

The simulations consider three representative mobility conditions:

* 30 mph — moderate mobility
* 90 mph — high mobility
* 150 mph — very high mobility

Increasing velocity affects the channel in two ways:

1. The UE moves through different large-scale propagation environments more rapidly.
2. The Doppler frequency increases, producing faster small-scale channel variation.

⸻

4. Propagation Model

The received power is modeled using a combination of path loss, shadowing, and small-scale fading.

A general received-power model can be expressed as

$$
P_r(d)

P_t
+
G_t
+
G_r

PL(d)
+
X_\sigma
+
F,
$$

where:

* (P_t) is transmit power,
* (G_t) and (G_r) are transmitter and receiver antenna gains,
* (PL(d)) is distance-dependent path loss,
* (X_\sigma) represents log-normal shadowing,
* (F) represents small-scale fading in dB.

⸻

4.1 Path Loss

The baseline cellular model uses a distance-dependent path-loss model of the form

$$
PL(d)

128.1
+
37.6\log_{10}(d_{\mathrm{km}}),
$$

where (d_{\mathrm{km}}) is the transmitter-to-UE distance in kilometers.

The model captures the large-scale reduction in received signal power as the UE moves away from a serving cell.

⸻

4.2 Shadowing

Log-normal shadowing is used to represent large-scale variations caused by obstacles and local propagation environments.

The shadowing term is modeled as a Gaussian random variable in dB:

$$
X_\sigma \sim \mathcal{N}(0,\sigma^2).
$$

Representative standard deviations are:

$$
\sigma_{\mathrm{macro}} = 12\ \mathrm{dB},
$$

and

$$
\sigma_{\mathrm{small}} = 14\ \mathrm{dB}.
$$

The shadowing component is applied independently to the relevant propagation links in the system-level model.

⸻

5. Small-Scale Fading

The baseline implementations use Rayleigh fading to represent rapid signal fluctuations caused by multipath propagation.

For a complex baseband channel coefficient,

$$
h \sim \mathcal{CN}(0,1).
$$

The corresponding channel power gain is

$$
|h|^2.
$$

The received signal power can therefore be represented as

$$
P_r \propto |h|^2.
$$

Rayleigh fading is particularly useful for investigating how rapidly changing small-scale propagation conditions interact with high user mobility.

⸻

6. Doppler Modeling

6.1 Maximum Doppler Frequency

For a UE moving with velocity (v), the maximum Doppler frequency is approximated by

$$
f_D

\frac{v}{\lambda}

\frac{v f_c}{c},
$$

where:

* (v) is the UE velocity,
* (\lambda) is the wavelength,
* (f_c) is the carrier frequency,
* (c) is the speed of light.

The wavelength is

$$
\lambda = \frac{c}{f_c}.
$$

At a fixed carrier frequency, the Doppler frequency therefore increases approximately linearly with UE velocity.

⸻

6.2 Time-Correlated Fading

Independent fading samples at every simulation step would not accurately represent a continuously moving wireless channel.

The Doppler-aware implementation therefore introduces temporal correlation into the fading process.

The simulated fading sequence is generated from random samples and processed using a Doppler-dependent low-pass filtering approach.

Conceptually,

$$
h(t)

\mathcal{F}_{f_D}{w(t)},
$$

where:

* (w(t)) represents a random excitation process,
* (\mathcal{F}_{f_D}) represents the Doppler-dependent filtering operation,
* (h(t)) is the resulting time-correlated fading process.

The resulting channel varies more rapidly as the Doppler frequency increases.

Modeling Note

This implementation is a system-level approximation of Doppler-induced temporal correlation. It is not intended to reproduce an exact Jakes/Clarke Doppler spectrum.

The more detailed 5G NR CDL implementation provides a higher-fidelity alternative for selected experiments.

⸻

7. SINR Model

At each time step, the serving-cell signal is distinguished from interference generated by other cells.

The signal-to-interference-plus-noise ratio is defined as

$$
\mathrm{SINR}

\frac{P_{\mathrm{signal}}}
{P_{\mathrm{interference}} + P_{\mathrm{noise}}}.
$$

In linear scale, the received powers are summed before calculating SINR.

The corresponding dB representation is

$$
\mathrm{SINR}_{\mathrm{dB}}

10\log_{10}(\mathrm{SINR}).
$$

SINR serves as the central link-quality metric in the simulation framework.

⸻

8. Noise Model

The thermal noise power is approximated by

$$
P_N = kTB,
$$

where:

* (k) is the Boltzmann constant,
* (T) is the reference temperature,
* (B) is the system bandwidth.

The receiver noise figure is incorporated into the effective noise level.

In dBm, the thermal noise power can be represented as

$$
P_N[\mathrm{dBm}]

-174
+
10\log_{10}(B)
+
NF,
$$

where:

* (B) is expressed in Hz,
* (NF) is the receiver noise figure in dB.

For the representative configuration,

$$
B = 10\ \mathrm{MHz},
\qquad
NF = 7\ \mathrm{dB}.
$$

⸻

9. Throughput Model

The instantaneous achievable throughput is approximated using the Shannon capacity expression

$$
R

B\log_2(1+\mathrm{SINR}),
$$

where (B) is the channel bandwidth.

The resulting throughput is converted to Mbps for visualization and comparison.

This model provides a theoretical upper-bound-style system-level estimate rather than a full 5G NR scheduler or modulation-and-coding implementation.

Therefore, the throughput results should be interpreted primarily for relative performance comparison across mobility, deployment, and antenna configurations.

⸻

10. Cell Association

At each simulation time step, the UE evaluates the candidate cells and identifies the strongest serving link according to the implemented association criterion.

The serving cell can therefore change as the UE moves through the network.

The basic process is:

Candidate Cells
      │
      ▼
Received Link Quality
      │
      ▼
Best Serving Cell
      │
      ▼
Current Serving Cell

This mechanism allows the simulation to capture mobility-induced changes in cell association.

⸻

11. Handover Modeling

A handover occurs when the selected serving cell changes from the previously serving cell.

The handover count is therefore updated according to

$$
N_{\mathrm{HO}}
\leftarrow
N_{\mathrm{HO}} + 1
$$

whenever

$$
\mathrm{Cell}{t}
\neq
\mathrm{Cell}{t-1}.
$$

The total handover frequency is used as a mobility-management metric.

A high handover rate may indicate that the UE is moving rapidly through overlapping coverage regions or that the deployment contains many closely spaced cells.

⸻

12. Radio Link Failure

Radio Link Failure is used to characterize severe and persistent link degradation.

An RLF event is triggered when

$$
\mathrm{SINR}{\mathrm{dB}}
<
\gamma{\mathrm{RLF}}
$$

for longer than a configured timeout:

$$
T_{\mathrm{RLF}}

0.2\ \mathrm{s}.
$$

The RLF mechanism therefore distinguishes between:

* temporary SINR fluctuations,
* and persistent link degradation.

This is particularly important for high-mobility scenarios, where short-term fading events may otherwise be incorrectly interpreted as complete connectivity failures.

⸻

13. SISO Modeling

The SISO implementation provides a reference configuration with one transmit and one receive antenna.

The SISO system is used as the baseline for evaluating the impact of spatial processing.

Its main outputs are:

* SINR
* Throughput
* Handover events
* RLF events

The SISO implementation provides a direct comparison point for the subsequent MIMO experiments.

⸻

14. MIMO Modeling

The project includes two different levels of MIMO modeling.

14.1 Simplified MIMO Gain

The baseline system-level implementation uses a simplified MIMO gain:

$$
\mathrm{SINR}_{\mathrm{MIMO,dB}}

\mathrm{SINR}{\mathrm{SISO,dB}}
+
G{\mathrm{MIMO}},
$$

where the representative gain is

$$
G_{\mathrm{MIMO}} = 3\ \mathrm{dB}.
$$

This approach provides a computationally inexpensive way to investigate the potential system-level impact of MIMO.

⸻

14.2 Explicit MIMO Configuration

The Monte Carlo MIMO implementation explicitly defines the transmit and receive antenna dimensions.

For the 2×2 configuration:

$$
N_t = 2,
\qquad
N_r = 2.
$$

This allows the simulation to distinguish antenna configuration from the simplified link-budget approximation.

The explicit MIMO simulations are used for statistical comparisons under multiple channel realizations.

⸻

15. Monte Carlo Evaluation

Wireless channel realizations are stochastic. A single fading realization may therefore produce results that are not representative of the underlying system behavior.

Monte Carlo simulations address this issue by repeating the experiment over multiple channel realizations.

For a metric (X), the empirical mean is

$$
\bar{X}

\frac{1}{N}
\sum_{i=1}^{N} X_i,
$$

where (N) is the number of realizations.

The simulations can therefore characterize both:

* average system performance,
* and performance variability.

This is particularly useful for comparing SISO and MIMO configurations.

⸻

16. 5G NR CDL Channel Model

The project includes a higher-fidelity channel implementation using MATLAB 5G Toolbox.

The mobility_cdL_1x2_MIMO.m implementation uses a Clustered Delay Line (CDL-D) channel model with a 1×2 antenna configuration.

Compared with the simplified Rayleigh fading implementation, the CDL model provides a more detailed representation of multipath propagation.

The channel incorporates effects including:

* Multipath components
* Delay spread
* Time-varying fading
* Doppler effects
* Multiple receive antennas
* Spatial channel variation

The CDL implementation therefore serves as a higher-fidelity extension of the system-level modeling framework.

⸻

17. Simulation Scenarios

The simulations investigate three representative UE mobility conditions:

Scenario	Velocity	Purpose
Low Mobility	30 mph	Moderate channel variation
High Mobility	90 mph	Stronger Doppler effects
Very High Mobility	150 mph	Severe mobility-induced variation

These scenarios are evaluated across different network and antenna configurations.

⸻

18. Deployment Configurations

The baseline simulation considers several cellular deployment types.

Macro-Only

The UE is served by a macro-cell network.

This configuration provides a reference for large-cell coverage and relatively infrequent cell transitions.

Macro + Small Cells

Small cells are introduced into the macro-cell environment.

This configuration allows the effect of heterogeneous networks on signal quality and handover behavior to be investigated.

Dense Small-Cell Deployment

A denser small-cell configuration is used to examine the trade-off between improved local signal strength and increased handover activity.

⸻

19. Simulation Pipeline

The complete simulation process can be summarized as:

System Parameters
       │
       ▼
Cellular Deployment
       │
       ▼
UE Mobility
       │
       ▼
Distance Calculation
       │
       ▼
Path Loss
       │
       ├──────────────┐
       ▼              ▼
   Shadowing      Small-Scale Fading
                        │
                        ▼
                     Doppler
                        │
                        ▼
             Received Signal Power
                        │
                        ▼
                 Interference + Noise
                        │
                        ▼
                       SINR
                 ┌──────┴──────┐
                 ▼             ▼
            Throughput    Cell Association
                                │
                                ▼
                             Handover
                                │
                                ▼
                               RLF

⸻

20. Modeling Assumptions

The following assumptions define the scope of the simulations.

System-Level Abstraction

The project focuses on system-level behavior rather than detailed physical-layer link-level simulation.

Propagation

Path loss, shadowing, and fading are modeled using analytical approximations.

Throughput

Throughput is estimated using Shannon capacity rather than a full 5G NR modulation and coding scheme.

Handover

Handover is represented using a simplified cell-association mechanism rather than a complete 3GPP mobility-management protocol stack.

RLF

RLF is modeled using a configurable SINR threshold and persistence timeout.

Doppler

The Doppler-aware Rayleigh implementation uses a filtering-based approximation of temporal channel correlation.

CDL

The CDL implementation provides a higher-fidelity channel model but is used as an extension rather than replacing the system-level baseline.

⸻

21. Model Fidelity

The different implementations provide progressively more detailed representations of the wireless channel:

Implementation	Channel Representation	Antenna Model	Evaluation
Baseline	Path loss + shadowing + Rayleigh	Simplified MIMO gain	Single simulation
Doppler	Time-correlated Rayleigh	System-level	Mobility study
SISO	Time-varying channel	1×1	Reference
Monte Carlo MIMO	Stochastic channel	2×2	Statistical
CDL	5G NR CDL-D	1×2	Higher fidelity

This progression allows the project to balance computational efficiency and physical modeling fidelity.

⸻

22. Reproducibility

To reproduce the simulations:

1. Install MATLAB.
2. Add the repository to the MATLAB path.
3. Run the desired simulation script under src/.
4. Adjust system parameters at the beginning of the corresponding script.
5. Save the resulting metrics and figures under results/.

The CDL implementation additionally requires the MATLAB 5G Toolbox.

For meaningful comparisons, system parameters should remain fixed while changing only the experimental variable of interest, such as:

* UE velocity
* Deployment configuration
* Antenna configuration
* Channel model

⸻

23. Summary

The methodology establishes a progressive framework for studying cellular connectivity under mobility.

Starting from a conventional system-level propagation model, the project introduces Doppler-dependent temporal fading, Monte Carlo statistical evaluation, explicit MIMO configurations, and finally a 5G NR CDL channel model.

The resulting framework connects physical channel variation to system-level connectivity metrics:

$$
\boxed{
\text{Mobility}
\rightarrow
\text{Doppler}
\rightarrow
\text{Channel Variation}
\rightarrow
\text{SINR}
\rightarrow
\text{Throughput / Handover / RLF}
}
$$

This structure provides a consistent basis for comparing mobility conditions, cellular deployment strategies, and antenna configurations.
