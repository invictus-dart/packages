/*
 * Distributed under the Boost Software License, Version 1.0.(See accompanying 
 * file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.)
 * 
 * See http://www.boost.org/libs/iostreams for documentation.

 * File:        boost/iostreams/detail/execute.hpp
 * Date:        Thu Dec 06 13:21:54 MST 2007
 * Copyright:   2007-2008 CodeRage, LLC
 * Author:      Jonathan Turkanis
 * Contact:     turkanis at coderage dot com
 *
 * Defines the preprocessor symbol BOOST_IOSTREAMS_HAS_DINKUMWARE_FPOS for
 * platforms that use the implementation of std::fpos from the Dinkumware 
 * Standard Library.
 */

#ifndef BOOST_IOSTREAMS_DETAIL_CONFIG_FPOS_HPP_INCLUDED
#define BOOST_IOSTREAMS_DETAIL_CONFIG_FPOS_HPP_INCLUDED

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

// [invictus-dart local fix -- do not sync back to upstream Tencent/mars]
// std::fpos in MSVC STL 14.1+ (VS2017+) is standard-conforming; newer MSVC
// STL (here _MSVC_STL_UPDATE 202503L) additionally removed fpos::seekpos()
// and the _FPOSOFF macro as a C++23 conformance cleanup, so positioning.hpp
// fails on the Dinkumware branch with error C2039 ("seekpos" is not a
// member of "std::fpos<_Mbstatet>") and error C3861 (_FPOSOFF: identifier
// not found).
// Fix matches upstream Boost (boostorg/iostreams develop branch,
// detail/config/fpos.hpp): with MSVC STL >= 141, do not define
// BOOST_IOSTREAMS_HAS_DINKUMWARE_FPOS; positioning.hpp then takes the
// standard conversion path.
#include <boost/config.hpp>
#include <boost/iostreams/detail/ios.hpp>
# if (defined(_YVALS) || defined(_CPPLIB_VER)) && !defined(__SGI_STL_PORT) && \
     !defined(_STLPORT_VERSION) && !defined(__QNX__) && \
     !((defined(BOOST_MSVC) || defined(BOOST_CLANG) || defined(_MSVC_STL_VERSION)) \
         && _MSVC_STL_VERSION >= 141) \
     && !defined(_LIBCPP_VERSION)
     /**/
#  define BOOST_IOSTREAMS_HAS_DINKUMWARE_FPOS
# endif

#endif // #ifndef BOOST_IOSTREAMS_DETAIL_CONFIG_FPOS_HPP_INCLUDED
