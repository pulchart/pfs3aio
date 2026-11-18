/* The build identity in the version strings of the handler and pfsdoctor
 * names the compiler, the tier, the CPUs the build runs on, and the fork and
 * the tag or commit it was built from. Every variant otherwise reports the same revision, so
 * C:Version and the ROM module listing cannot tell one gcc build from
 * another. Placed right after the revision because those listings truncate
 * the string.
 */
#ifndef PFSBUILD_H
#define PFSBUILD_H

#define PFS_STR2(x) #x
#define PFS_STR(x) PFS_STR2(x)

#if defined(__GNUC__)
#define PFS_CC "gcc" PFS_STR(__GNUC__) "." PFS_STR(__GNUC_MINOR__)
#else
#define PFS_CC "cc"
#endif

/* The makefile passes the tag as bare tokens, never numbers: 040 would be
 * octal. PFS_TIER is what the build is tuned for; PFS_MIN with PFS_ONLY,
 * PFS_TOP or PFS_MAX is where it runs. The predefine chain below is the
 * fallback for a hand build, and it cannot name either: a tier compiled
 * -m68060 reports itself as 060 whether it is the 060 build or not.
 */
#if defined(PFS_ONLY)
#define PFS_RANGE "[" PFS_STR(PFS_MIN) "]"
#elif defined(PFS_TOP)
#define PFS_RANGE "[" PFS_STR(PFS_MIN) "+]"
#elif defined(PFS_MAX)
#define PFS_RANGE "[" PFS_STR(PFS_MIN) "-" PFS_STR(PFS_MAX) "]"
#else
#define PFS_RANGE ""
#endif

#if defined(PFS_TIER)
#define PFS_CPU PFS_STR(PFS_TIER)
#elif defined(__mc68080__)
#define PFS_CPU "080"
#elif defined(__mc68060__) || defined(__M68060)
#define PFS_CPU "060"
#elif defined(__mc68040__) || defined(__M68040)
#define PFS_CPU "040"
#elif defined(__mc68020__) || defined(__M68020)
#define PFS_CPU "020"
#else
#define PFS_CPU "000"
#endif

/* Origin: which fork and which source, the tag if HEAD carries one and the
 * commit otherwise. Absent from a build made with upstream's makefile, which
 * passes none of these.
 */
#if defined(PFS_FORK)
#define PFS_ORIGIN "[" PFS_STR(PFS_FORK) "/" PFS_STR(PFS_REF) "]"
#else
#define PFS_ORIGIN ""
#endif

#define PFS_BUILD "[" PFS_CC "/" PFS_CPU "]" PFS_RANGE PFS_ORIGIN " "

#endif
