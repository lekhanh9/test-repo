// ghost-escape bridging header
// Exposes the ClearSword entry point and the sandbox escape to Swift.
//
// Requires HEADER_SEARCH_PATHS to include $(SRCROOT)/Exploit/clearsword
// (set in project.yml / Xcode build settings).

#import <Foundation/Foundation.h>

#include "poc.h"      // int clearsword_run(void)
#include "sandbox.h"  // int sandbox_escape(uint64_t self_proc); void sandbox_dump(uint64_t, size_t);
#include "token.h"    // int ghost_issue_token(const char*, uint32_t, char**); int ghost_escape_other(pid_t);

// Real-time log bridge: the C exploit routes its LOG/LOG_ERR/LOG_DEBUG
// macros through this symbol (see common.h). Declared here so Swift can
// also emit phase markers; the symbol itself is provided by Swift via
// @_cdecl (LogManager.swift) and hops to the main queue.
void swift_log(const char* msg);
