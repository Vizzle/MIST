//  MARK: Formatter Exempt
//  VZCommonDefine.h
//  MIST
//
//  Created by John Wong on 12/19/16.
//  Copyright © 2016 Vizlab. All rights reserved.
//

#ifndef VZCommonDefine_h
#define VZCommonDefine_h

// define of weakify and strongify
#define weakify(var) ext_keywordify __weak typeof(var) O2OWeak_##var = var;
#define strongify(var) ext_keywordify \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = O2OWeak_##var; \
_Pragma("clang diagnostic pop")
#if DEBUG
#   define ext_keywordify autoreleasepool {}
#else
#   define ext_keywordify try {} @catch (...) {}
#endif

// define of defer
typedef void (^ext_cleanupBlock_t)();
static inline void ext_executeCleanupBlock(__strong ext_cleanupBlock_t *block)
{
    (*block)();
}
#define __SCOPEGUARD_CONCATENATE_IMPL(s1, s2) s1##s2
#define __SCOPEGUARD_CONCATENATE(s1, s2) __SCOPEGUARD_CONCATENATE_IMPL(s1, s2)
#define defer ext_keywordify \
__strong ext_cleanupBlock_t __SCOPEGUARD_CONCATENATE(ext_exitBlock_, __LINE__) __attribute__((cleanup(ext_executeCleanupBlock), unused)) = ^


#endif /* VZCommonDefine_h */
