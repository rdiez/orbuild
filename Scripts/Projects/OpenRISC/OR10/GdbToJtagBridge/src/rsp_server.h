
#ifndef RSP_SERVER_H_INCLUDED
#define RSP_SERVER_H_INCLUDED

void handle_rsp ( int port_number, bool listen_on_local_addr_only, bool trace_rsp, bool trace_jtag, const bool * exit_request );

#endif	// Include this header file only once.
