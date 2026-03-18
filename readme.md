# Digitally Controlled Buck Converter (P & PI) with Burst Mode (Verilog)

## 📌 Overview
This project implements a **digitally controlled buck converter** using Verilog HDL with:

- Proportional (P) Controller  
- Proportional-Integral (PI) Controller  
- Burst Mode Operation for light-load efficiency  

The design is targeted for **low-power applications** such as IoT sensor nodes, where efficiency at light load is critical.

---

## 🚀 Features
- Digital PWM generation
- P and PI control loops
- Burst mode switching for reduced power consumption
- Saturation and clamping for stability
- Fixed-point (Q8) arithmetic implementation
- Modular and synthesizable Verilog design

---

## 📂 Project Structure
verilog/
├── buck_siso_ctrl_p_burst.v # P controller implementation
├── buck_siso_ctrl_pi_burst.v # PI controller implementation


---

## ⚙️ Working Principle

### 🔹 P Controller
- Control Law:

Duty = Base + Kp × Error

- Simple and fast response
- May have steady-state error

---

### 🔹 PI Controller
- Control Law:

Duty = Base + Kp × Error + Ki × ∑Error

- Eliminates steady-state error
- Better accuracy for output regulation

---

### 🔹 Burst Mode Operation
- Enabled during light-load conditions
- Uses hysteresis:
- Upper threshold: `V_HIGH_CODE`
- Lower threshold: `V_LOW_CODE`
- Reduces switching losses by enabling/disabling PWM in packets

---

## 🧮 Key Parameters

| Parameter        | Description                     |
|-----------------|---------------------------------|
| `F_CLK_HZ`      | System clock frequency          |
| `F_PWM_HZ`      | PWM switching frequency         |
| `PWM_TOP`       | PWM resolution                  |
| `Kp_Q8`         | Proportional gain (Q8 format)   |
| `Ki_Q8`         | Integral gain (Q8 format)       |
| `BASE_DUTY_PCT` | Base duty cycle (%)             |

---

## 🛠️ Simulation Setup

### Tools Used
- Icarus Verilog (Simulation)
- GTKWave (Waveform Viewer)

### Run Simulation
```bash
iverilog -o sim.vvp testbench.v buck_siso_ctrl_pi_burst.v
vvp sim.vvp
gtkwave dump.vcd