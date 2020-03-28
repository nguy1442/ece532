/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

#include <stdio.h>
#include <string.h>

//BSP includes for peripherals
#include "xparameters.h"
#include "netif/xadapter.h"
#include "xil_io.h"
#include "packet_switcher_ip.h"

#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#endif

int transfer_data() {
	return 0;
}

void print_app_header()
{
#if (LWIP_IPV6==0)
	xil_printf("\n\r\n\r-----lwIP TCP config server ------\n\r");
#else
	xil_printf("\n\r\n\r-----lwIPv6 TCP config server ------\n\r");
#endif
	xil_printf("Listening to TCP packets sent to port 6001\n\r");
}

static void tcp_server_close(struct tcp_pcb *pcb)
{
	err_t err;

	xil_printf("Closing Server Connection\n");

	if (pcb != NULL) {
		tcp_sent(pcb, NULL);
		tcp_recv(pcb, NULL);
		tcp_err(pcb, NULL);
		err = tcp_close(pcb);
		if (err != ERR_OK) {
			/* Free memory with abort */
			tcp_abort(pcb);
		}
	}
}

int send_response(char *send_buf, unsigned int num_char, struct tcp_pcb *tpcb) {
	err_t err;

	//Just send a single packet
	u8_t apiflags = TCP_WRITE_FLAG_COPY | TCP_WRITE_FLAG_MORE;

	//Loop until enough room in buffer (should be right away)
	while (tcp_sndbuf(tpcb) < num_char);

	//Enqueue some data to send
	err = tcp_write(tpcb, send_buf, num_char, apiflags);
	if (err != ERR_OK) {
		xil_printf("TCP server: Error on tcp_write: %d\n", err);
		return err;
	}

	//send the data packet
	err = tcp_output(tpcb);
	if (err != ERR_OK) {
		xil_printf("TCP server: Error on tcp_output: %d\n",err);
		return err;
	}

	xil_printf("Response sent\n");
	return 0;
}

err_t process_message(char *message, unsigned int len, struct tcp_pcb *tpcb) {
	char buf[255];
	unsigned int s_len;
	err_t err = ERR_OK;

	if (memcmp(message, "status", 6) == 0) {
		// Client is asking for counters
		unsigned int port_a_received = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG4_OFFSET);
		unsigned int port_b_received = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG5_OFFSET);
		unsigned int port_c_received = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG6_OFFSET);
		unsigned int port_a_dropped = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG8_OFFSET);
		unsigned int port_b_dropped = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG9_OFFSET);
		unsigned int port_c_dropped = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG10_OFFSET);

		s_len = sprintf(buf, "Port A received: %u\n"
							 "Port B received: %u\n"
							 "Port C received: %u\n"
							 "Port A dropped: %u\n"
							 "Port B dropped: %u\n"
							 "Port C dropped: %u\n",
							 port_a_received,
							 port_b_received,
							 port_c_received,
							 port_a_dropped,
							 port_b_dropped,
							 port_c_dropped
						);

		err = send_response(buf, s_len, tpcb);
	} else if (memcmp(message, "iptable -l", 10) == 0) {
		// Client is asking for iptable
		unsigned int port_a_address = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG0_OFFSET);
		unsigned int port_b_address = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG1_OFFSET);
		unsigned int port_c_address = PACKET_SWITCHER_IP_mReadReg(XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR, PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG2_OFFSET);

		//xil_printf("port a address bits: %h", port_a_address);

		s_len = sprintf(buf, "IP address table: \n"
							 "Port A address: %hhu.%hhu.%hhu.%hhu\n"
							 "Port B address: %hhu.%hhu.%hhu.%hhu\n"
							 "Port C address: %hhu.%hhu.%hhu.%hhu\n",
							 (unsigned char)((port_a_address >> 24) & 0x0FF),
							 (unsigned char)((port_a_address >> 16) & 0x0FF),
							 (unsigned char)((port_a_address >> 8) & 0x0FF),
							 (unsigned char)((port_a_address >> 0) & 0x0FF),
							 (unsigned char)((port_b_address >> 24) & 0x0FF),
							 (unsigned char)((port_b_address >> 16) & 0x0FF),
							 (unsigned char)((port_b_address >> 8) & 0x0FF),
							 (unsigned char)((port_b_address >> 0) & 0x0FF),
							 (unsigned char)((port_c_address >> 24) & 0x0FF),
							 (unsigned char)((port_c_address >> 16) & 0x0FF),
							 (unsigned char)((port_c_address >> 8) & 0x0FF),
							 (unsigned char)((port_c_address >> 0) & 0x0FF)
						);

		err = send_response(buf, s_len, tpcb);
	} else if ((memcmp(message, "iptable -s", 10) == 0) && (len >= 21)) {
		// Client is asking to modify the iptable
		if(memcmp(message + 10, " a", 2) == 0) {
			char *end;
			char *start = message + 12;

			unsigned int test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG0_OFFSET+3) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG0_OFFSET+2) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG0_OFFSET+1) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG0_OFFSET+0) = test;
		} else if(memcmp(message + 10, " b", 2) == 0) {
			char *end;
			char *start = message + 12;

			unsigned int test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG1_OFFSET+3) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG1_OFFSET+2) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG1_OFFSET+1) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG1_OFFSET+0) = test;
		} else if (memcmp(message + 10, " c", 2) == 0) {
			char *end;
			char *start = message + 12;

			unsigned int test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG2_OFFSET+3) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG2_OFFSET+2) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG2_OFFSET+1) = test;
			start = end + 1;

			test = strtol(start, &end, 10);
			*(char *) (XPAR_PACKET_SWITCHER_IP_0_CONFIG_AXI_S_BASEADDR + PACKET_SWITCHER_IP_CONFIG_AXI_S_SLV_REG2_OFFSET+0) = test;
		} else {
			// Client has sent a invalid command
			s_len = sprintf(buf, "Invalid command");

			err = send_response(buf, s_len, tpcb);
		}
	} else {
		// Client has sent a invalid command
		s_len = sprintf(buf, "Invalid command");

		err = send_response(buf, s_len, tpcb);
	}

	return err;
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{
	err_t s_err = ERR_OK;
	//If no data, connection closed
	if (!p) {
		xil_printf("No data received\n");
		tcp_server_close(tpcb);
		return ERR_OK;
	}

	xil_printf("Message received, %d bytes\n", p->tot_len);

	// Read message contents
	char* packet_data = (char*) malloc(p->tot_len);
	if(packet_data == NULL) {
		xil_printf("Error allocating memory for message\n");
		tcp_server_close(tpcb);
		return ERR_MEM;
	}

	pbuf_copy_partial(p, packet_data, p->tot_len, 0); //Note - inefficient way to access packet data
	u32_t i;

	for(i = 0; i < p->tot_len; i = i + 1)
		putchar(packet_data[i]);

	// Process the message
	if(p->tot_len >= 6) {
		s_err = process_message(packet_data, p->tot_len, tpcb);
	}

	free(packet_data);

	//Indicate done processing
	tcp_recved(tpcb, p->tot_len);

	//Free the received pbuf
	pbuf_free(p);

	return s_err;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	xil_printf("A Client has connected to the Server");

	return ERR_OK;
}


int start_application()
{
	struct tcp_pcb *pcb;
	err_t err;
	unsigned port = 7;

	/* create new TCP PCB structure */
	pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	/* bind to specified @port */
	err = tcp_bind(pcb, IP_ANY_TYPE, port);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/* listen for connections */
	pcb = tcp_listen(pcb);
	if (!pcb) {
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}

	/* specify callback to use for incoming connections */
	tcp_accept(pcb, accept_callback);

	xil_printf("TCP echo server started @ port %d\n\r", port);

	return 0;
}
