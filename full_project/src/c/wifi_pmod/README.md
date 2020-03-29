# Working with the ESP32 Wi-Fi PMOD code
> Before running the PMOD code...
- Make sure the UART IP in the block diagram is set to 115200 Baud Rate
- You need to use a serial terminal to view PMOD output/send AT commands if needed (I suggest TeraTerm/Putty, NOT the one in SDK as it doesn't send the '\r\n' properly
- Make sure the serial terminal is set to 115200 Baud Rate, and that it can send the Carriage Return + New Line characters properly
- Set up the terminal, THEN run the PMOD code on the Microblaze


> After running the PMOD code...
- If your terminal is set-up properly, you should see several lines of output, these consist of a bunch of AT commands and their associated responses that configure the PMOD appropriately
- Every AT command EXCEPT for 'AT+CIPCLOSE' should NOT return any errors (this command just guarantees that the connection is closed if we need to re-run the code over and over)
- You should see a prompt asking you to type in the 'port number' of the device that will undergo a UDP connection with the PMOD
- This prompt stalls the code from running, giving you time to connect the device to the Wi-Fi network (which should be active now, and named 'ESP32_ECE532') and double-check that the commands ran properly
- After connecting the device and ensuring no firewall is present on the device, enter the port number used for packet communication to the terminal (press 'Enter' to submit)
- After entering the port number, the PMOD will start a UDP connection and ping the device, if the ping fails then the code will restart the UDP connection (and re-prompt you)
- If the ping passes, you should see something along the lines of 'Entering ESP32 command-line interface...'
- Now the PMOD is able to send/recieve packets (assuming Mahmoud's UDP wrap/unwrap script is there)

> Troubleshooting...
- There's rare cases where the PMOD spams garbage characters to the terminal, burning your eye retinas, if this occurs then you can reset the PMOD by pressing the 'reset' button and it should be fixed
- There's other cases where if you mis-type the 'port number' in the user prompt, then the code kind of goes bonkers and spams the prompt, just restart the code if this happens
- Actually, a lot of stalling/spam problems can probably be dealt with by restarting the code/PMOD...
- You are also able to manually type in AT commands to see what's going on
- If you see commands failing with the message 'ERR CODE = 0X1030000 or ERR CODE = 0x1080000' then it's likely that there were stray characters in the UART buffer that got sent with the command, manually re-sending the command should fix it
- There are numerous commented out debug statements in the code that you can uncomment to view output details, ILAs would also be useful
- Wi-Fi Device --> Ethernet Device: PMOD sends a +IPD message, code parses that message for the packet data, and writes it to the AXI Stream TX FIFO
- Ethernet Device --> Wi-Fi Device: Code recieves data from the AXI Stream RX FIFO, sends it to the PMOD using the AT command 'AT+CIPSEND'
