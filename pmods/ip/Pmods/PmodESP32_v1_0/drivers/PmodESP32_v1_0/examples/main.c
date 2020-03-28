/* main.c */

/* Demo code borrowed by the Diligent Github Repo. that provides
 * a simple communication interface with the ESP32 through command
 * line, this is expanded on heavily to allow packets to go to-and-from the
 * ESP32 PMOD */

#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"

#include "PmodESP32.h"
#include "xllfifo.h"

#ifdef __MICROBLAZE__
#define HOST_UART_DEVICE_ID XPAR_AXI_UARTLITE_0_BASEADDR
#define FIFO_DEV_ID XPAR_AXI_FIFO_0_DEVICE_ID
#define HostUart XUartLite
#define HostUart_Config XUartLite_Config
#define HostUart_CfgInitialize XUartLite_CfgInitialize
#define HostUart_LookupConfig XUartLite_LookupConfig
#define HostUart_Recv XUartLite_Recv
#define HostUartConfig_GetBaseAddr(CfgPtr) (CfgPtr->RegBaseAddr)
#include "xuartlite.h"
#include "xil_cache.h"
#include "xstatus.h"
#else
#define HOST_UART_DEVICE_ID XPAR_PS7_UART_1_DEVICE_ID
#define HostUart XUartPs
#define HostUart_Config XUartPs_Config
#define HostUart_CfgInitialize XUartPs_CfgInitialize
#define HostUart_LookupConfig XUartPs_LookupConfig
#define HostUart_Recv XUartPs_Recv
#define HostUartConfig_GetBaseAddr(CfgPtr) (CfgPtr->BaseAddress)
#include "xuartps.h"
#endif

/* Defines */
#define PMODESP32_UART_BASEADDR XPAR_PMODESP32_0_AXI_LITE_UART_BASEADDR
#define PMODESP32_GPIO_BASEADDR XPAR_PMODESP32_0_AXI_LITE_GPIO_BASEADDR

// Wait time to allow some leeway for the PMOD to send its response to a command
#define UART_DELAY 50000

// Buffer length
#define UART_BUFF_LEN 256

// String versions of configuration parameters
#define NAME_PMOD "\"ESP32_ECE532\""
#define PWD_PMOD "\"123456789\""
#define PORT_PMOD "2233"
#define IPADDR_PMOD "\"192.168.4.1\""
#define IPADDR_WIFI_DEVICE_1 "\"192.168.4.2\""

/* Function Prototypes */
void EnableCaches();
void DisableCaches();
void DemoInitialize();
void DemoRun();
void DemoCleanup();

void configureESP32();
void sendCommandAT(char* command);
u8 sendCommandATandFlushRX(char* command);
u8 flushUART(u8 delay);

char* my_itoa(char* a, u32 i);
int my_atoi(u8 *a, u32 length);

void readAXIStreamandSendToPMOD();
void sendToAXIStream(u8* data, u32 length);

/* Instance variables */
PmodESP32 myESP32;
XLlFifo FifoInstance;
HostUart myHostUart;

void DemoInitialize () {

	// Configure UART <--> PMOD
	HostUart_Config *CfgPtr;
	EnableCaches();
	ESP32_Initialize(&myESP32, PMODESP32_UART_BASEADDR, PMODESP32_GPIO_BASEADDR);
	CfgPtr = HostUart_LookupConfig(HOST_UART_DEVICE_ID);
	HostUart_CfgInitialize(&myHostUart, CfgPtr, HostUartConfig_GetBaseAddr(CfgPtr));
	xil_printf("UART connection to PMOD initialization done!\r\n");

	// Configure AXI Stream FIFO
	int Status;
    XLlFifo_Config *Config = XLlFfio_LookupConfig(FIFO_DEV_ID);
	if (!Config) xil_printf("WARNING: No device config found for %d (AXI Stream FIFO)\r\n", FIFO_DEV_ID);

	Status = XLlFifo_CfgInitialize(&FifoInstance, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) xil_printf("WARNING: AXI Stream FIFO Initialization failed\n\r");

	Status = XLlFifo_Status(&FifoInstance);
	XLlFifo_IntClear(&FifoInstance, 0xffffffff);
	Status = XLlFifo_Status(&FifoInstance);
	if(Status != 0x0)
		xil_printf("\n WARNING : In AXI Stream FIFO - Reset value of ISR0 : 0x%x\t"
			    "Expected : 0x0\n\r",
			    XLlFifo_Status(&FifoInstance));

	xil_printf("AXI Stream FIFO initialization done!\r\n");

	// Configure ESP32
	configureESP32();
}

/* Main body of code, perpetual loop that runs forever */
void DemoRun() {

	u8 recv_char;
	u32 num_received;

	u8 PMOD_rx[UART_BUFF_LEN*2]; // Buffer to store PMOD response/output
	u32 p = 0; // Index into 'PMOD_rx', how many characters are contained minus 1

	// Flag variables to parse +IPD commands (PMOD sending us packet data)
	u32 seenIPD = 0;
	u32 seenColon = 0;

	// Indexes into 'PMOD_rx' that determine where the relevant +IPD fields are
	u32 IPDleng_index_start = 0;
	u32 IPDdata_index_start = 0;
	u32 IPDleng_index_end = 0;
	u32 IPDdata_index_end = 0;

	xil_printf("\r\nConfiguration of ESP32 done! Entering Pmod ESP32 Command Line Interface!\r\n");
	xil_printf("Enter AT commands to interact with the ESP32!\r\n\r\n");

	while (1) {

		// Constantly poll the ESP32 UART buffer and print the contents
		num_received = ESP32_Recv(&myESP32, &recv_char, 1);
		if (num_received > 0) {
			xil_printf("%c", recv_char);
			//xil_printf("R%x-", recv_char); // <- DEBUG: Hex output

			PMOD_rx[p] = recv_char; // Place character in receive buffer
			p++;
		}

		// Constantly poll the terminal and print the contents
		num_received = HostUart_Recv(&myHostUart, &recv_char, 1);
		if (num_received > 0) {
			xil_printf("%c", recv_char);
			//xil_printf("T%x-", recv_char); // <- DEBUG: Hex output
			while (0 == ESP32_Send(&myESP32, &recv_char, 1));
		}


		// Poll the AXI Stream FIFO RX side and check if any packets came in
		// so we can transmit them to the PMOD
		if(XLlFifo_iRxOccupancy(&FifoInstance)) {
			readAXIStreamandSendToPMOD();
		}


		/* This huge blob of code constantly parses the UART data that the
		 * PMOD spits out, grabbing any incoming packet data that comes in
		 * and sends it to the AXI Stream FIFO TX Side */

		// Overflow, not good :(
		if (p > UART_BUFF_LEN*2) {
			xil_printf("WARNING: PMOD RX buffer overflow, flushing everything\r\n");
			p = 0;
			seenIPD = 0;
			seenColon = 0;
			IPDleng_index_start = 0;
			IPDdata_index_start = 0;
			IPDleng_index_end = 0;
			IPDdata_index_end = 0;
		}

		// Seen a NewLine + Carriage Return, flush the buffer
		else if (p > 1 && PMOD_rx[p-1] == '\n' && PMOD_rx[p-2] == '\r') {
			p = 0;
			seenIPD = 0;
			seenColon = 0;
			IPDleng_index_start = 0;
			IPDdata_index_start = 0;
			IPDleng_index_end = 0;
			IPDdata_index_end = 0;
		}

		// Check for '+IPD,' signifying received packet data
		else if (!seenIPD && p > 4 && PMOD_rx[p-1] == ',' && PMOD_rx[p-2] == 'D'
				&& PMOD_rx[p-3] == 'P' && PMOD_rx[p-4] == 'I' && PMOD_rx[p-5] == '+') {

			// DEBUG
			//xil_printf("\r\n   DEBUG: '+IPD,' sequence seen, length should be at index %d of PMOD_rx\r\n", p);

			seenIPD = 1;
			IPDleng_index_start = p; // Length of packet data appears right after the comma which was at 'p-1'
		}

		// Check for colon...
		// The character BEFORE the colon 'p-2' is the LAST character of the string with the packet length
		// The characters FOLLOWING the colon are the actual packet data
		else if (!seenColon && p > 1 && seenIPD && PMOD_rx[p-1] == ':') {

			// DEBUG
			//xil_printf("\r\n   DEBUG: ':' seen, data should be at index %d of PMOD_rx\r\n", p);

			seenColon = 1;
			IPDleng_index_end = p-2;
			IPDdata_index_start = p;

			// Convert the string containing the length into an integer,
			// then use that to establish how many characters we expect the
			// packet data to be
			u32 leng_index_length = IPDleng_index_end - IPDleng_index_start + 1;
			u32 data_length = my_atoi(&PMOD_rx[IPDleng_index_start], leng_index_length);
			IPDdata_index_end = p + data_length - 1;

			// DEBUG
			//xil_printf("\r\n   DEBUG: Data is %d characters long, should end at index %d of PMOD_rx\r\n", data_length, IPDdata_index_end);
		}

		// We have reached the end of the packet data, now we
		// send it to the AXI Stream FIFO TX side
		else if (seenIPD && seenColon && (p == IPDdata_index_end + 1)) {
			u32 data_length = IPDdata_index_end - IPDdata_index_start + 1;
			//xil_printf("Data Indices: %d %d\r\n", IPDdata_index_start, IPDdata_index_end); // <- DEBUG, see data indices

			sendToAXIStream(&PMOD_rx[IPDdata_index_start], data_length);

			// Must set these flags to 0 so we do not continually enter this block of code
			seenColon = 0;
			seenIPD = 0;
			IPDleng_index_start = 0;
			IPDdata_index_start = 0;
			IPDleng_index_end = 0;
			IPDdata_index_end = 0;
		}
	}
}

/* Sends some preliminary commands to configure the ESP32 */
void configureESP32() {
	xil_printf("\r\nSetting the ESP32 as an Access Point!\r\n");

	sendCommandATandFlushRX("ATE0\r\n"); // Disable PMOD repeating what we transmit
	sendCommandATandFlushRX("AT+CIPCLOSE\r\n"); // Force-close connection
	sendCommandATandFlushRX("AT+CWMODE=2\r\n"); // Set PMOD as Access Point

	// Set network name and password (which interestingly doesn't seem to work)
	sendCommandAT("AT+CWSAP=");
	sendCommandAT(NAME_PMOD);
	sendCommandAT(",");
	sendCommandAT(PWD_PMOD);
	sendCommandATandFlushRX(",1,0,4,0\r\n");

	// Set IP address
	sendCommandAT("AT+CIPAP=");
	sendCommandAT(IPADDR_PMOD);
	sendCommandAT(",");
	sendCommandAT(IPADDR_PMOD);
	sendCommandATandFlushRX(",\"255.255.255.0\"\r\n");

	// Superficially poll user for the 'Port #' of the device
	// that is connecting to the Wi-Fi
	u8 UDPconnected = 0;
	u8 pollDone = 0;
	u8 user_char, received;
	char rx_user[16];
	u8 i = 0;

	xil_printf("\r\nInitial configuration of ESP32 done, if you see a WARNING\r\n");
	xil_printf("related to the command AT+CIPCLOSE, you can ignore it, any\r\n");
	xil_printf("other warning, then something bad probably happened, and you should not proceed...\r\n\r\n");

	do {
		xil_printf("Starting a UDP connection, make sure you connect your\r\n");
		xil_printf("device to the ESP32 Wi-Fi network before beginning\r\n");
		xil_printf("and type in the port number of the connected device so we can\r\n");
		xil_printf("establish a UDP connection: ");

		while (!pollDone) {
			received = HostUart_Recv(&myHostUart, &user_char, 1);

			if (received > 0) {
				rx_user[i] = user_char;

				// Exit polling if we overfill, or user presses 'ENTER'
				if (i >= 15 || (i > 0 && rx_user[i] == '\n' && rx_user[i-1] == '\r')) {
					pollDone = 1;
					rx_user[i-1] = '\0'; // Null terminate the user inputted string
				}

				i++;
			}
		}

		xil_printf("You entered the port number: %s\r\n", rx_user);

		// Now we establish the UDP connection
		sendCommandAT("AT+CIPSTART=\"UDP\",");
		sendCommandAT(IPADDR_WIFI_DEVICE_1);
		sendCommandAT(",");
		sendCommandAT(rx_user);
		sendCommandAT(",");
		sendCommandAT(PORT_PMOD);
		sendCommandATandFlushRX(",0\r\n");

		// Tell the PMOD to bing the device and confirm the connection is fine
		sendCommandAT("AT+PING=");
		sendCommandAT(IPADDR_WIFI_DEVICE_1);
		sendCommandAT("\r\n");

		// Flush UART for a longer time for the ping to finish
		if (flushUART(20)) {
			xil_printf("\r\nUDP connection failed, retrying...\r\n");
			pollDone = 0;
			sendCommandATandFlushRX("AT+CIPCLOSE\r\n"); // Force-close connection
		}

		else {
			UDPconnected = 1;
		}

	} while (!UDPconnected);

}

/* Transmits a command, but do not wait for the PMOD to respond,
 * this is mainly used when we need to send a large command that is split
 * over multiple 'sendCommandAT' calls (only the last call would require us
 * to wait for the PMOD response) */
void sendCommandAT(char* command) {
	u32 length = strlen(command);
	xil_printf("%s", command);
	ESP32_SendBuffer(&myESP32, command, length);
}

/* Transmits a command over the UART, ideally an AT command,
 * stall for a while and wait for the PMOD to send its response */
u8 sendCommandATandFlushRX(char* command) {
	u32 length = strlen(command);
	xil_printf("%s", command);
    ESP32_SendBuffer(&myESP32, command, length);

	if (flushUART(1)) {
		xil_printf("WARNING: The following ESP32 command returned an error: %s\r\n", command);
		return 1;
	}

	return 0;
}

/* Delay for some duration of time to wait for the PMOD
 * to send its characters, this will clear the RX buffer,
 * returns 1 if the response contains ERROR, 0 otherwise */
u8 flushUART(u8 delay) {

	u8 rx[UART_BUFF_LEN];
	u8 j = 0;
	u8 recv_char;
	u8 error_found = 0;

	for (int i = 0; i < UART_DELAY*delay; i++) {
		u8 received = ESP32_Recv(&myESP32, &recv_char, 1);

		if (received > 0 && j < UART_BUFF_LEN-1) {
			rx[j] = recv_char;

			// Check for '\r\nERR' in the command
			if (!error_found && j > 3 && rx[j] == 'R' && rx[j-1] == 'R') {
				if (rx[j-2] == 'E'  && rx[j-3] == '\n' && rx[j-4] == '\r') {
					error_found = 1;
				}
			}

			j++;
		}
	}

	/* DEBUG statement, shows the PMOD response */
	rx[j] = '\0';
    if (j > 0) xil_printf("%s", rx);

	return error_found;
}


/* Rudimentary function that converts a string 'a' to its
 * integer equivalent 'i', assume the string length is defined properly
 */
int my_atoi(u8 *a, u32 length) {
	int i = 0;
	int digitScale = 1;

	if (length < 1 || length > 5) {
		xil_printf("WARNING: Specified string produces too large of an integer, returning 1...\r\n");
		return 1;
	}

	for (int j = 0; j < length; j++) {
		char digit = a[length-(1+j)];

		if (digit < '0' || digit > '9') {
			xil_printf("WARNING: Character not a digit, using 0 instead\r\n");
			digit = '0';
		}

		int digitInt = digit - '0'; // Character arithmetic, might be buggy?
		i += digitInt * digitScale;
		digitScale *= 10;
	}

	return i;
}


/* Rudimentary function that converts an integer 'i' to its
 * string equivalent 'a', assume that 'a' is at least 5 elements
 */
char* my_itoa(char* a, u32 i) {

	u32 j = 0;
	char const digit[] = "0123456789";
	char* b = a;
	b[0] = '1';
	b[1] = '\0';

	// Forcibly return '1' for any integers bigger than 2048,
	// the PMOD can't support packets that large anyways...
	if (i > 2048) return b;
	int shift = i;

	do { // Move to where the integer ends
		j++;
		shift = shift/10; // Integer division
	} while (shift);

	b[j] = '\0';

	do {
		j--;
		b[j] = digit[i % 10];
		i = i/10;
	} while(i);

	return b;
}

// Read the incoming packet data from the AXI Stream FIFO
// and transmit them to the PMOD
void readAXIStreamandSendToPMOD() {
	u8 rx[UART_BUFF_LEN]; // Store packets received from the AXI Stream FIFO
	int i;
	u32 RxWord;
	u32 ReceiveLength;

	// Read Receive Length, this is originally in bytes, convert to words
	// A N-byte packet is sent as N words in this FIFO
	ReceiveLength = (XLlFifo_iRxGetLen(&FifoInstance))/4;

	if(ReceiveLength != 0)
		xil_printf("\r\nAXI Stream FIFO RX - Receiving packet of size %d\r\n", ReceiveLength);

	if (ReceiveLength > UART_BUFF_LEN) {
		ReceiveLength = UART_BUFF_LEN;
		xil_printf("WARNING: Received packet exceeding buffer length, truncating it!\r\n");
	}

	// Fill in the buffer, 1 byte at a time
	for (i=0; i < ReceiveLength; i++) {
		RxWord = XLlFifo_RxGetWord(&FifoInstance);
		rx[i] = (u8) RxWord; // Only grab the relevant byte, might be buggy?

		// DEBUG
		// xil_printf("%x ", RxWord);
		// xil_printf("%x ", rx[i]);
	}

	xil_printf("\r\n");

	// Now send the whole thing to the PMOD
	char lengStr[5];
	sendCommandAT("AT+CIPSEND=");
	sendCommandAT(my_itoa(lengStr, ReceiveLength));
	sendCommandATandFlushRX("\r\n");

	// Don't use 'sendCommandATandFlushRX' as the 'strlen' in the function will truncate
	// the buffer upon seeing a null byte in the packet, which we probably don't want
	ESP32_SendBuffer(&myESP32, rx, ReceiveLength);
	flushUART(1);
}

// Send the incoming packet data to the
// AXI Stream FIFO TX side, assumes length is well-defined
void sendToAXIStream(u8* data, u32 length) {
	u32 remaining = XLlFifo_iTxVacancy(&FifoInstance); // Check how many bytes the FIFO has
	xil_printf("\r\nAXI Stream FIFO TX - Transmitting packet of size %d, %d spots in the FIFO remaining\r\n", length, remaining);

	if (length > remaining) { // Drop the packet if FIFO has no room
		xil_printf("WARNING: FIFO has no room, dropping the packet!\r\n");
		return;
	}

	XLlFifo_WriteTdr(&FifoInstance, 0); // Don't care what value we write

	for (int i = 0; i < length; i++) {
		u32 TxWord = data[i]; // Assigning u8 to a u32
		XLlFifo_TxPutWord(&FifoInstance, TxWord);

		// DEBUG
	    // xil_printf("%x ", TxWord);
		// xil_printf("%x ", data[i]);
	}

	xil_printf("\r\n");

	/* Start Transmission by writing transmission length into the TLR */
	XLlFifo_iTxSetLen(&FifoInstance, 4*length);

	// Comment out for now, do not need to block for the FIFO?
	//while( !(XLlFifo_IsTxDone(InstancePtr)) ) {}
}

void DemoCleanup() {
	DisableCaches();
}


int main() {
	DemoInitialize();
	DemoRun();
	DemoCleanup();
	return 0;
}

void EnableCaches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
   Xil_DCacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
   Xil_ICacheEnable();
#endif
#endif
}

void DisableCaches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
   Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
   Xil_ICacheDisable();
#endif
#endif
}
