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
  - Contains testbenches used to simulate the input_queue and arbitrator modules from the Packer Switcher Custom IP

Procedure to build the project:
1. Download the repo
2. Run the build tcl script
    1. Open Vivado (preferabley same version 2018.1 used to create the project)
    2. Navigate to <location to downloaded repo>/full_project/proj/
    3. Run source network_switch_build.tcl
    4. This will build the project at <location to downloaded repo>/full_project/proj/network_switch and create the block diagram
3. Create a HDL wrapper for the block diagram and run Generate Bitstream and export hardware including the bitstream
4. Launch SDK and create two applications
    1. For the config microblaze create a new application and use the lwIP Echo Server template and replace the main.c and echo.c file with the files in <location to downloaded repo>/full_project/src/c/eth_config/
    2. For the wifi microblaze create a new empty application and add the main.c file in <location to downloaded repo>/full_project/src/c/wifi_pmod/
    3. Modify the linker scripts so that the application for the config microblaze is programmed the DDR memory (MIG 7 Series) and the application for the wifi microblaze is programmed to the local bram memory
5. Follow step 10 from https://reference.digilentinc.com/learn/programmable-logic/tutorials/nexys-4-ddr-getting-started-with-microblaze-servers/start to set the PHY link speed
6. Everything required for the project should now be built. Connect the board to program the hardware onto the FPGA and program the microblazes using the Xilinx C/C++ application (System Debugger) configuration (NOT Xilinx C/C++ Application (GDB) because that cannot configure multiple microblazes)
