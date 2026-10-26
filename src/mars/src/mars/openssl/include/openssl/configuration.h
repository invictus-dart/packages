/*
 * Vendored per-architecture configuration dispatcher for OpenSSL 3.5.9.
 *
 * The ConanCenter prebuilt static packages for MSVC (x86_64 and armv8)
 * ship identical headers except `configuration.h`, which is generated
 * per target architecture. This dispatcher selects the matching
 * generated configuration at compile time.
 *
 * x86 (ia32) has no OpenSSL 3.5.9 prebuilt on ConanCenter; building for
 * x86 requires compiling OpenSSL from source first.
 */

#ifndef OPENSSL_VENDORED_CONFIGURATION_DISPATCHER_H
#define OPENSSL_VENDORED_CONFIGURATION_DISPATCHER_H
#pragma once

#if defined(_M_ARM64)
#  include <openssl/configuration_windows-arm64.h>
#elif defined(_M_X64) || defined(_M_AMD64)
#  include <openssl/configuration_windows-x86_64.h>
#elif defined(_M_IX86)
#  error "OpenSSL 3.5.9 has no x86 (ia32) prebuilt library; build it from source if x86 support is required."
#else
#  error unsupported platform
#endif

#endif /* OPENSSL_VENDORED_CONFIGURATION_DISPATCHER_H */
