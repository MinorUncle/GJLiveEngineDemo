//
//  rvopserver.h
//  AirFloat
//
//  Copyright (c) 2013, Kristian Trenskow All rights reserved.
//
//  Redistribution and use in source and binary forms, with or
//  without modification, are permitted provided that the following
//  conditions are met:
//
//  Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the following
//  disclaimer in the documentation and/or other materials provided
//  with the distribution. THIS SOFTWARE IS PROVIDED BY THE
//  COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
//  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#ifndef _rvopserver_h
#define _rvopserver_h

#include <stdint.h>
#include <stdbool.h>

struct rvop_server_settings_t {
    const char* name;
    const char* password;
    bool ignore_source_volume;
};

typedef struct rvop_server_t *rvop_server_p;

#ifndef _rsp
typedef struct rvop_session_t *rvop_session_p;
#define _rsp
#endif

typedef void(*rvop_server_new_session_callback)(rvop_server_p server, rvop_session_p new_session, void* ctx);
typedef bool(*rvop_server_accept_callback)(rvop_server_p server, const char* connection_host, uint16_t connection_port, void* ctx);

rvop_server_p rvop_server_create(struct rvop_server_settings_t settings);
void rvop_server_destroy(rvop_server_p rs);
bool rvop_server_start(rvop_server_p rs, uint16_t port);
bool rvop_server_is_running(rvop_server_p rs);
bool rvop_server_is_recording(rvop_server_p rs);
struct rvop_server_settings_t rvop_server_get_settings(rvop_server_p rs);
void rvop_server_set_settings(rvop_server_p rs, struct rvop_server_settings_t settings);
void rvop_server_stop(rvop_server_p rs);
void rvop_server_set_new_session_callback(rvop_server_p rs, rvop_server_new_session_callback new_session_callback, void* ctx);
void rvop_server_set_session_accept_callback(rvop_server_p rs, rvop_server_accept_callback session_accept_callback, void* ctx);

#endif
