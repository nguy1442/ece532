# Network Switch ECE532 Project
Outline of repo:

- docs/
    - Contains all documentation. This includes the group final report, the presentation slides, and video demonstrating the project
- full_project/
    - proj/
        - Contains the tcl scripts which create the project and build the block diagram
    - src/
        - Contains the source code to the LWIP server for remote configuration and Wi-Fi PMOD driver
        - Contains the constraints file for the project
        - Contains python scripts to issue commands to the LWIP server and scripts for sending/receiving udp packets from the Wi-Fi connected device 
- packet_switcher/ip_repo/packet_switcher_ip_1.0/
  - Contains the packaged Packer Switcher Custom IP with source code in the hdl/ folder
- pmod_nic100/ip_repo/pmod_nic100_axi_stream_ip_1.0/
  - Contains the packaged NIC100 AXI Stream Custom IP with source code in the hdl/ folder
- pmods/
  - Contains the Digilent provided IPs to communicate with the ESP32 Wi-Fi PMOD
- testbenches/
  -Contains testbenches used to simulate the input_queue and arbitrator modules from the Packer Switcher Custom IP
