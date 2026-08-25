Methodology

This document describes the system-level modeling methodology used in the Cellular Communication System Modeling under Mobility project.

The simulation framework progressively incorporates propagation loss, shadowing, small-scale fading, mobility-induced Doppler effects, cellular association, handover, radio link failure, and SISO/MIMO configurations.

⸻

1. System Model

The system consists of multiple base stations and a mobile user equipment (UE).

At each simulation time step, the UE position is updated according to its velocity. The received power from each candidate cell is then calculated based on propagation loss, shadowing, fading, and channel variation.

The overall modeling pipeline is:

<table align="center">
  <tr>
    <td align="center"><b>UE Mobility</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Distance to Base Stations</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Path Loss + Shadowing</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Small-Scale Fading</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Doppler-Induced Channel Variation</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Received Signal + Interference</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>SINR</b></td>
  </tr>
</table>

The resulting SINR is then used to evaluate throughput, cell association, handover behavior, and radio link failure.

⸻

2. Simulation Parameters

The representative system-level configuration is summarized below.

Parameter	Value
Carrier frequency	3.5 GHz
Bandwidth	10 MHz
Noise figure	7 dB
Simulation duration	20 s
Time step	0.01 s
UE velocity	30 / 90 / 150 mph
Macro shadowing standard deviation	12 dB
Small-cell shadowing standard deviation	14 dB
Baseline MIMO gain	3 dB
RLF timeout	0.2 s

Some parameters vary between exploratory implementations. The values above represent the primary system-level configuration.

⸻

3. Mobility Model

The UE moves through the cellular deployment at a predefined velocity.

The three representative mobility conditions are:

Scenario	Velocity	Description
Low Mobility	30 mph	Moderate mobility
High Mobility	90 mph	High mobility
Very High Mobility	150 mph	Extreme mobility

For a simulation time (t), the UE position can be represented as

$$\mathbf{p}(t) = [x(t), y(t)]^T$$

where (x(t)) and (y(t)) denote the horizontal coordinates of the UE.

Increasing UE velocity affects the system through two primary mechanisms:

* Faster movement through large-scale propagation environments.
* Increased Doppler frequency and faster small-scale channel variation.

⸻

4. Propagation Model

The received signal power is modeled using path loss, shadowing, and small-scale fading.

A general received-power model is

$$P_r(d) = P_t + G_t + G_r - PL(d) + X_{\sigma} + F$$

where:

Symbol	Description
(P_t)	Transmit power
(G_t)	Transmitter antenna gain
(G_r)	Receiver antenna gain
(PL(d))	Distance-dependent path loss
(X_{\sigma})	Log-normal shadowing
(F)	Small-scale fading contribution

The model combines large-scale propagation effects with rapidly varying small-scale channel conditions.

⸻

4.1 Path Loss

The baseline cellular model uses the following distance-dependent path-loss model:

$$PL(d) = 128.1 + 37.6\log_{10}(d_{\mathrm{km}})$$

where (d_{\mathrm{km}}) is the transmitter-to-UE distance in kilometers.

This model captures the reduction in received power as the UE moves farther from a base station.

⸻

4.2 Shadowing

Log-normal shadowing is used to represent slow variations in received power caused by obstacles and local propagation environments.

The shadowing term is modeled as

$$X_{\sigma} \sim \mathcal{N}(0,\sigma^2)$$

with representative standard deviations of

$$\sigma_{\mathrm{macro}} = 12\ \mathrm{dB}$$

and

$$\sigma_{\mathrm{small}} = 14\ \mathrm{dB}$$

for macro and small-cell links, respectively.

⸻

5. Small-Scale Fading

The baseline implementations use Rayleigh fading to model rapid signal fluctuations caused by multipath propagation.

A normalized complex channel coefficient can be represented as

$$h \sim \mathcal{CN}(0,1)$$

and the corresponding channel power gain is

$$G_{\mathrm{fading}} = |h|^2$$

The received signal power is therefore affected by both large-scale propagation and small-scale fading.

⸻

6. Doppler Modeling

6.1 Maximum Doppler Frequency

For a UE moving with velocity (v), the maximum Doppler frequency is approximated by

$$f_D = \frac{v}{\lambda} = \frac{v f_c}{c}$$

where:

Symbol	Description
(v)	UE velocity
(\lambda)	Carrier wavelength
(f_c)	Carrier frequency
(c)	Speed of light

The wavelength is given by

$$\lambda = \frac{c}{f_c}$$

Therefore, for a fixed carrier frequency, Doppler frequency increases approximately linearly with UE velocity.

⸻

6.2 Time-Correlated Fading

Independent fading samples at every simulation step would not accurately represent a continuously moving wireless channel.

The Doppler-aware implementation therefore introduces temporal correlation into the fading process using a Doppler-dependent filtering approach.

Conceptually, the generated fading process can be represented as

$$h[n] = \mathcal{F}_{f_D}{w[n]}$$

where:

* (w[n]) is a random excitation sequence.
* (\mathcal{F}_{f_D}) represents the Doppler-dependent filtering operation.
* (h[n]) is the resulting time-correlated fading process.

As (f_D) increases, the channel varies more rapidly with time.

Modeling note: This implementation is a system-level approximation of Doppler-induced temporal correlation. It is not intended to reproduce an exact Jakes/Clarke Doppler spectrum. The 5G NR CDL implementation provides a higher-fidelity channel model for selected experiments.

⸻

7. SINR Model

At each time step, the serving-cell signal is distinguished from interference generated by other cells.

The signal-to-interference-plus-noise ratio is defined as

$$\mathrm{SINR} = \frac{P_{\mathrm{signal}}}{P_{\mathrm{interference}} + P_{\mathrm{noise}}}$$

The corresponding dB representation is

$$\mathrm{SINR}{\mathrm{dB}} = 10\log{10}(\mathrm{SINR})$$

SINR is the primary instantaneous link-quality metric in the simulation framework.

⸻

8. Noise Model

The thermal noise power is given by

$$P_N = kTB$$

where:

Symbol	Description
(k)	Boltzmann constant
(T)	Reference temperature
(B)	System bandwidth

When expressed in dBm, the effective receiver noise power is approximated by

$$P_N[\mathrm{dBm}] = -174 + 10\log_{10}(B) + NF$$

where:

* (B) is the bandwidth in Hz.
* (NF) is the receiver noise figure in dB.

For the representative configuration:

$$B = 10\ \mathrm{MHz}$$

and

$$NF = 7\ \mathrm{dB}$$

⸻

9. Throughput Model

The instantaneous achievable throughput is approximated using the Shannon capacity expression

$$R = B\log_2(1+\mathrm{SINR})$$

where (B) is the system bandwidth.

The resulting data rate is converted to Mbps for visualization and comparison.

This model is intended for system-level comparison rather than detailed 5G NR link-level throughput prediction. It does not explicitly model scheduling, modulation and coding schemes, HARQ, or protocol overhead.

⸻

10. Cell Association

At each simulation time step, the UE evaluates the candidate cells and selects the serving cell according to the implemented link-quality criterion.

The cell-association process can be summarized as:

<table align="center">
  <tr>
    <td align="center"><b>Candidate Cells</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Received Link Quality</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Serving Cell Selection</b></td>
  </tr>
</table>

As the UE moves, the selected serving cell may change.

⸻

11. Handover Modeling

A handover event is recorded when the selected serving cell changes.

The handover count can be represented as

$$N_{\mathrm{HO}} \leftarrow N_{\mathrm{HO}} + 1$$

when

$$\mathrm{Cell}t \neq \mathrm{Cell}{t-1}$$

The total number of handovers is used as a mobility-management metric.

A high handover rate can occur when the UE moves rapidly through overlapping coverage regions or when cells are densely deployed.

⸻

12. Radio Link Failure

Radio Link Failure (RLF) is used to characterize persistent link degradation.

An RLF condition is triggered when

$$\mathrm{SINR}{\mathrm{dB}} < \gamma{\mathrm{RLF}}$$

for longer than the configured timeout

$$T_{\mathrm{RLF}} = 0.2\ \mathrm{s}$$

The persistence requirement distinguishes temporary fading fluctuations from sustained connectivity degradation.

This is particularly important in high-mobility scenarios, where short-term fading events can cause temporary SINR drops without necessarily representing a complete link failure.

⸻

13. SISO Modeling

The SISO implementation provides a reference configuration with one transmit and one receive antenna.

The SISO system is used as a baseline for evaluating the effect of additional spatial degrees of freedom.

The primary outputs are:

* SINR
* Throughput
* Handover frequency
* Radio Link Failure

⸻

14. MIMO Modeling

The project contains two levels of MIMO modeling.

14.1 Simplified MIMO Gain

The baseline system-level implementation uses a simplified MIMO link-budget gain.

The effective SINR is modeled as

$$\mathrm{SINR}{\mathrm{MIMO,dB}} = \mathrm{SINR}{\mathrm{SISO,dB}} + G_{\mathrm{MIMO}}$$

with a representative gain of

$$G_{\mathrm{MIMO}} = 3\ \mathrm{dB}$$

This provides a computationally inexpensive method for evaluating the potential system-level impact of MIMO.

⸻

14.2 Explicit MIMO Configuration

The Monte Carlo MIMO implementation explicitly defines the transmit and receive antenna dimensions.

For the 2×2 configuration:

$$N_t = 2$$

$$N_r = 2$$

The explicit configuration allows antenna dimensions to be represented directly rather than through a fixed link-budget gain.

⸻

15. Monte Carlo Evaluation

Wireless channel realizations are stochastic. A single fading trajectory may therefore not be representative of the overall system behavior.

Monte Carlo simulations address this issue by repeating the experiment across multiple channel realizations.

For a metric (X), the empirical mean is

$$\bar{X} = \frac{1}{N}\sum_{i=1}^{N}X_i$$

where (N) is the number of independent realizations.

The Monte Carlo framework allows the simulations to characterize:

* Average SINR
* SINR distribution
* Average throughput
* Throughput distribution
* Handover frequency
* RLF probability

This is particularly useful for comparing SISO and MIMO configurations.

⸻

16. 5G NR CDL Channel Model

The project includes a higher-fidelity channel implementation using MATLAB 5G Toolbox.

The mobility_cdL_1x2_MIMO.m implementation uses a Clustered Delay Line (CDL-D) channel model with a 1×2 antenna configuration.

Compared with the simplified Rayleigh fading implementation, the CDL model provides a more detailed representation of multipath propagation.

The channel model incorporates:

* Multipath propagation
* Delay spread
* Doppler effects
* Time-varying fading
* Multiple receive antennas
* Spatial channel variation

The CDL implementation therefore serves as a higher-fidelity extension of the system-level modeling framework.

⸻

17. Simulation Scenarios

The simulations consider three representative UE mobility conditions:

<table align="center">
  <tr>
    <th>Scenario</th>
    <th>Velocity</th>
    <th>Purpose</th>
  </tr>
  <tr>
    <td align="center">Low Mobility</td>
    <td align="center">30 mph</td>
    <td align="center">Moderate channel variation</td>
  </tr>
  <tr>
    <td align="center">High Mobility</td>
    <td align="center">90 mph</td>
    <td align="center">Stronger Doppler effects</td>
  </tr>
  <tr>
    <td align="center">Very High Mobility</td>
    <td align="center">150 mph</td>
    <td align="center">Severe mobility-induced variation</td>
  </tr>
</table>

⸻

18. Deployment Configurations

The baseline simulation considers several cellular deployment configurations.

Macro-Only

The UE is served by a macro-cell network.

This configuration provides a reference for large-cell coverage and relatively infrequent cell transitions.

Macro + Small Cells

Small cells are introduced into the macro-cell environment.

This configuration allows the effects of heterogeneous deployment on signal quality and handover behavior to be investigated.

Dense Small-Cell Deployment

A denser small-cell configuration is used to investigate the trade-off between improved local signal strength and increased handover activity.

⸻

19. Complete Simulation Pipeline

The complete simulation workflow is summarized below.

<table align="center">
  <tr>
    <td align="center"><b>System Parameters</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Cellular Deployment</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>UE Mobility</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Distance Calculation</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Path Loss + Shadowing</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Small-Scale Fading + Doppler</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Received Signal + Interference</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>SINR</b></td>
  </tr>
</table>

The resulting SINR is then used by two main branches:

<table align="center">
  <tr>
    <td align="center"><b>SINR</b></td>
  </tr>
  <tr>
    <td align="center">↙　　　　　　　　　↘</td>
  </tr>
  <tr>
    <td align="center"><b>Throughput</b></td>
    <td align="center"><b>Cell Association</b></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"><b>Handover</b></td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"></td>
    <td align="center"><b>RLF</b></td>
  </tr>
</table>

⸻

20. Modeling Assumptions

The following assumptions define the scope of the simulations.

System-Level Abstraction

The project focuses on system-level behavior rather than detailed physical-layer link-level simulation.

Propagation

Path loss, shadowing, and fading are represented using analytical models.

Throughput

Throughput is estimated using Shannon capacity rather than a full 5G NR modulation and coding implementation.

Handover

Handover is represented using a simplified cell-association mechanism rather than a complete 3GPP mobility-management protocol stack.

RLF

RLF is modeled using a configurable SINR threshold and persistence timeout.

Doppler

The Doppler-aware Rayleigh implementation uses a filtering-based approximation of temporal channel correlation.

CDL

The CDL implementation provides a higher-fidelity 5G NR channel model and is used as an extension of the system-level baseline.

⸻

21. Model Fidelity

The different implementations provide progressively more detailed representations of the wireless channel.

<table align="center">
  <tr>
    <th>Implementation</th>
    <th>Channel Model</th>
    <th>Antenna Model</th>
    <th>Evaluation</th>
  </tr>
  <tr>
    <td>Baseline</td>
    <td>Path Loss + Shadowing + Rayleigh</td>
    <td>Simplified MIMO Gain</td>
    <td>System-Level</td>
  </tr>
  <tr>
    <td>Doppler</td>
    <td>Time-Correlated Rayleigh</td>
    <td>System-Level</td>
    <td>Mobility Study</td>
  </tr>
  <tr>
    <td>SISO</td>
    <td>Time-Varying Channel</td>
    <td>1×1</td>
    <td>Reference</td>
  </tr>
  <tr>
    <td>Monte Carlo MIMO</td>
    <td>Stochastic Channel</td>
    <td>2×2</td>
    <td>Statistical Evaluation</td>
  </tr>
  <tr>
    <td>CDL</td>
    <td>5G NR CDL-D</td>
    <td>1×2</td>
    <td>Higher Fidelity</td>
  </tr>
</table>

This progression allows computationally efficient system-level analysis to be compared with more detailed channel representations.

⸻

22. Reproducibility

To reproduce the simulations:

1. Install MATLAB.
2. Clone or download this repository.
3. Add the repository to the MATLAB path.
4. Navigate to the desired directory under src/.
5. Run the corresponding MATLAB script.
6. Save selected figures and numerical results under results/.

The CDL implementation additionally requires the MATLAB 5G Toolbox.

For meaningful comparisons, system parameters should remain fixed while changing only the experimental variable of interest, such as:

* UE velocity
* Deployment configuration
* Antenna configuration
* Channel model

⸻

23. Summary

The methodology establishes a progressive framework for studying cellular connectivity under mobility.

The project connects physical channel variation to system-level connectivity metrics through the following relationship:

<table align="center">
  <tr>
    <td align="center"><b>Mobility</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Doppler</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Channel Variation</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>SINR</b></td>
  </tr>
  <tr>
    <td align="center">↓</td>
  </tr>
  <tr>
    <td align="center"><b>Throughput / Handover / RLF</b></td>
  </tr>
</table>

The resulting framework provides a consistent basis for comparing mobility conditions, cellular deployment strategies, and antenna configurations under progressively more realistic wireless channel models.
