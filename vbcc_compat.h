#ifndef _VBCC_COMPAT_H
#define _VBCC_COMPAT_H 1

/* vbcc-only shims. Empty for every other compiler, so including this is a
 * no-op for the gcc and SAS/C builds. See TOOLCHAINS.md, "vbcc".
 */
/* Functions that hand-written assembly calls by name. Under -fastcall vbcc
 * gives every C function an @ prefix, which startup.s cannot reference, so
 * these keep the standard convention and their plain _ prefix. Harmless
 * without -fastcall, where that is the convention anyway, and empty for every
 * other compiler.
 */
#if defined(__VBCC__)
#define ASMLINKAGE __stdargs
#else
#define ASMLINKAGE
#endif

#if defined(__VBCC__)

#ifndef EXEC_LISTS_H
#include <exec/lists.h>
#endif

/* stpcpy() is a GNU extension and vbcc's string.h does not declare it.
 * The implementation lives in assroutines.c, so only a prototype is needed.
 */
extern char *stpcpy(char *dst, const char *src);

/* implemented in vbcc_compat.c */
extern int stricmp(const char *a, const char *b);

#endif /* __VBCC__ */
#endif /* _VBCC_COMPAT_H */
