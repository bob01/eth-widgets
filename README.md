[![GitHub license](https://img.shields.io/github/license/bob01/etxwidgets)](https://github.com/bob01/etxwidgets/main/LICENSE)


# Welcome to ethWidgets for FrSky ETHOS
**Screen elements for R/C Helicopters (RotorFlight v2.1+) and Airplanes**


### About etxWidgets
These widgets and custom layouts have been designed by R/C pilots for R/C pilots.
The goal is to present the relevant telemetry expected from modern R/C systems before, during and after flight with on-screen, audio and haptic elements.<br>
These layouts and widgets can be used to build screens like these.
Model files will be included in the near future - decided to share now due to several requests for the ePowerbar widget for ETHOS

Helicopter without trims + ESC / govenor status<br>
![image](https://github.com/user-attachments/assets/eb71ebbd-2f91-4f79-ba94-80c9d7a3831f)<br>
Airplane with trims + FrSky stabilizer status<br>
![image](https://github.com/user-attachments/assets/e4992cfd-0e16-4558-8a41-9b924102297b)<br>
Summary screen<br>
![image](https://github.com/user-attachments/assets/799cb8b8-97e2-4b6d-9030-60f81d628cdd)<br>

### Requirements
- ETHOS 1.6.2 or later (https://ethos.frsky-rc.com/)
- RotorFlight 2.1 or later (https://github.com/rotorflight)
- Rotorflight Lua Suite for Ethos (https://github.com/rotorflight/rotorflight-lua-ethos-suite)

### Release notes
- 2025.02.06 - initial release


# ePowerbar
![image](https://github.com/user-attachments/assets/2437e345-9da1-4442-8c6f-a43d43875b52)
![image](https://github.com/user-attachments/assets/8b0a8df8-78a5-44d7-9ad7-09afc15e5b53)
![image](https://github.com/user-attachments/assets/30124be1-ad9e-4462-bdab-246ac1048a00)


### Features
- does voice callouts every 10% w/ 1% callouts for the last 10
- use 'Battery %' or 'Fuel' telemetry sensor from flightcontroller where available or set capacity explicity
- use cell count telemetry sensor from flight controller where available or set explicitly
- changes color to yellow at 30% and red for the last 20% or...
- allows specification of a "reserve" %. In that case pilot flys to 0, bar goes red if pilot chooses to go further
- critial alerts will be accompanied by a haptic vibe
- voltage alerts when cell voltages below low or critical thresholds can be always on or based on a condition

### Settings
![image](https://github.com/user-attachments/assets/2f49aa7b-116e-4d1e-ad78-8a28c4bd4f5f)
![image](https://github.com/user-attachments/assets/9d9c0b0c-3cc7-4c79-9d4d-1d6eb6f57dd1)
![image](https://github.com/user-attachments/assets/121a3d93-cb42-4230-8326-8ad5099abb5b)


# eGovernor
![image](https://github.com/user-attachments/assets/eb71ebbd-2f91-4f79-ba94-80c9d7a3831f)
![image](https://github.com/user-attachments/assets/681b1763-7c65-4119-8b77-e6772a0fcb84)
![image](https://github.com/user-attachments/assets/1abd754f-ff99-4272-9896-a17f48fc1b19)


### Features
- uses RotorFlight's (FC) flight mode telemetry sensor to indicate the actual true "safe" / "armed" state of the flight controller w/ voice callout
- displays the FC's flight mode telemetry sensor to help tell what's happening if you're standing there and FC won't arm
- displays ESC last most significant status + log of last 128 messages in full screen mode, purpose is to help understand unexpected powerloss etc at the flightline or pits w/o a laptop
- can be used with airplanes (displays FrSky SR stabilizer status)

### Settings
![image](https://github.com/user-attachments/assets/aa46cb99-8f5a-4300-9fed-29326d6ebf50)
![image](https://github.com/user-attachments/assets/473fba76-081d-47e1-aee5-3572a42d8137)

# eBitmap
![image](https://github.com/user-attachments/assets/591fb44e-7c38-45f7-9086-a0515c5b5111)


### Features
- uses RotorFlight EthOS suite to get model name from the flight controller
- allows single Tx model to be used for multiple helis


# Custom Layouts
- Heli main screen (no trims)
- Airplane main screen (with trims)
- 12 cell summary screen<br>
![image](https://github.com/user-attachments/assets/63b4e708-538d-4832-a148-6e32e89a688c)
![image](https://github.com/user-attachments/assets/b49d8fe4-b634-454b-8050-9f6127f3a36f)
![image](https://github.com/user-attachments/assets/113d04a2-3c4f-42c4-bd4d-61b1ea817d27)

  

# Installation
- download eth-widgets-main.zip (don't unzip it)
- use ethos suite v1.6 or above to install as shown below
  ![image](https://github.com/user-attachments/assets/3218e57c-b803-432c-a4ff-1b7081294873)
  ![image](https://github.com/user-attachments/assets/150c09bd-4d1f-4feb-b1b7-89d0c60a7bc6)



