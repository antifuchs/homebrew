require 'formula'

# Nethack the way God intended it to be played: from a terminal.
# This build script was created referencing:
# * http://nethackwiki.com/wiki/Compiling#On_Mac_OS_X
# * http://nethackwiki.com/wiki/Pkgsrc#patch-ac_.28system.h.29
# and copious hacking until things compiled.
#
# The patch applied incorporates the patch-ac above, the OS X
# instructions from the Wiki, and whatever else needed to be
# done.

class Nethack <Formula
  @url='http://downloads.sourceforge.net/project/nethack/nethack/3.4.3/nethack-343-src.tgz'
  @homepage='http://www.nethack.org/index.html'
  @version='3.4.3'
  @md5='21479c95990eefe7650df582426457f9'

  # Don't remove save folder
  skip_clean 'libexec/save'

  def patches
    DATA
  end

  def install
    fails_with_llvm
    # Build everything in-order; no multi builds.
    ENV.deparallelize

    # Symlink makefiles
    system 'sh sys/unix/setup.sh'

    inreplace "include/config.h",
      /^#\s*define HACKDIR.*$/,
      "#define HACKDIR \"#{libexec}\"
       #define MENU_COLOR 1
       #define MENU_COLOR_REGEX_POSIX 1
       #define PARANOID 1"
    
    # Make the data first, before we munge the CFLAGS
    system "cd dat;make"

    Dir.chdir 'dat' do
      %w(perm logfile).each do |f|
        system "touch", f
        libexec.install f
      end

      # Stage the data
      libexec.install %w(help hh cmdhelp history opthelp wizhelp dungeon license data oracles options rumors quest.dat)
      libexec.install Dir['*.lev']
    end

    # Make the game
    ENV.append_to_cflags "-I../include"
    system 'cd src;make'

    bin.install 'src/nethack'
    (libexec+'save').mkpath
  end
end

__END__
diff --git a/.gitignore b/.gitignore
new file mode 100644
index 0000000..8b2ccd2
--- /dev/null
+++ b/.gitignore
@@ -0,0 +1,2 @@
+*.o
+*.lev
diff --git a/include/system.h b/include/system.h
index a4efff9..cfe96f1 100644
--- a/include/system.h
+++ b/include/system.h
@@ -79,10 +79,10 @@ typedef long	off_t;
 # if !defined(__SC__) && !defined(LINUX)
 E  long NDECL(random);
 # endif
-# if (!defined(SUNOS4) && !defined(bsdi) && !defined(__FreeBSD__)) || defined(RANDOM)
+# if (!defined(SUNOS4) && !defined(bsdi) && !defined(__NetBSD__) && !defined(__FreeBSD__) && !defined(__DragonFly__) && !defined(__APPLE__)) || defined(RANDOM)
 E void FDECL(srandom, (unsigned int));
 # else
-#  if !defined(bsdi) && !defined(__FreeBSD__)
+#  if !defined(bsdi) && !defined(__NetBSD__) && !defined(__FreeBSD__) && !defined(__DragonFly__) && !defined(__APPLE__)
 E int FDECL(srandom, (unsigned int));
 #  endif
 # endif
@@ -132,7 +132,7 @@ E void FDECL(perror, (const char *));
 E void FDECL(qsort, (genericptr_t,size_t,size_t,
 		     int(*)(const genericptr,const genericptr)));
 #else
-# if defined(BSD) || defined(ULTRIX)
+# if defined(BSD) || defined(ULTRIX) && !defined(__NetBSD__)
 E  int qsort();
 # else
 #  if !defined(LATTICE) && !defined(AZTEC_50)
@@ -421,7 +421,7 @@ E size_t FDECL(strlen, (const char *));
 # ifdef HPUX
 E unsigned int	FDECL(strlen, (char *));
 #  else
-#   if !(defined(ULTRIX_PROTO) && defined(__GNUC__))
+#   if !(defined(ULTRIX_PROTO) && defined(__GNUC__)) && !defined(__NetBSD__)
 E int	FDECL(strlen, (const char *));
 #   endif
 #  endif /* HPUX */
@@ -476,9 +476,9 @@ E  char *sprintf();
 #  if !defined(SVR4) && !defined(apollo)
 #   if !(defined(ULTRIX_PROTO) && defined(__GNUC__))
 #    if !(defined(SUNOS4) && defined(__STDC__)) /* Solaris unbundled cc (acc) */
-E int FDECL(vsprintf, (char *, const char *, va_list));
-E int FDECL(vfprintf, (FILE *, const char *, va_list));
-E int FDECL(vprintf, (const char *, va_list));
+// E int FDECL(vsprintf, (char *, const char *, va_list));
+// E int FDECL(vfprintf, (FILE *, const char *, va_list));
+// E int FDECL(vprintf, (const char *, va_list));
 #    endif
 #   endif
 #  endif
@@ -521,7 +521,7 @@ E struct tm *FDECL(localtime, (const time_t *));
 #  endif
 # endif
 
-# if defined(ULTRIX) || (defined(BSD) && defined(POSIX_TYPES)) || defined(SYSV) || defined(MICRO) || defined(VMS) || defined(MAC) || (defined(HPUX) && defined(_POSIX_SOURCE))
+# if defined(ULTRIX) || (defined(BSD) && defined(POSIX_TYPES)) || defined(SYSV) || defined(MICRO) || defined(VMS) || defined(MAC) || (defined(HPUX) && defined(_POSIX_SOURCE)) || defined(__NetBSD__)
 E time_t FDECL(time, (time_t *));
 # else
 E long FDECL(time, (time_t *));
diff --git a/include/unixconf.h b/include/unixconf.h
index fe1b006..3a195a6 100644
--- a/include/unixconf.h
+++ b/include/unixconf.h
@@ -19,20 +19,20 @@
  */
 
 /* define exactly one of the following four choices */
-/* #define BSD 1 */	/* define for 4.n/Free/Open/Net BSD  */
+#define BSD 1 	/* define for 4.n/Free/Open/Net BSD  */
 			/* also for relatives like SunOS 4.x, DG/UX, and */
 			/* older versions of Linux */
 /* #define ULTRIX */	/* define for Ultrix v3.0 or higher (but not lower) */
 			/* Use BSD for < v3.0 */
 			/* "ULTRIX" not to be confused with "ultrix" */
-#define SYSV		/* define for System V, Solaris 2.x, newer versions */
+/* #define SYSV */		/* define for System V, Solaris 2.x, newer versions */
 			/* of Linux */
 /* #define HPUX */	/* Hewlett-Packard's Unix, version 6.5 or higher */
 			/* use SYSV for < v6.5 */
 
 
 /* define any of the following that are appropriate */
-#define SVR4		/* use in addition to SYSV for System V Release 4 */
+/* #define SVR4 */		/* use in addition to SYSV for System V Release 4 */
 			/* including Solaris 2+ */
 #define NETWORK		/* if running on a networked system */
 			/* e.g. Suns sharing a playground through NFS */
@@ -285,8 +285,8 @@
 
 #if defined(BSD) || defined(ULTRIX)
 # if !defined(DGUX) && !defined(SUNOS4)
-#define memcpy(d, s, n)		bcopy(s, d, n)
-#define memcmp(s1, s2, n)	bcmp(s2, s1, n)
+// #define memcpy(d, s, n)      bcopy(s, d, n)
+// #define memcmp(s1, s2, n)    bcmp(s2, s1, n)
 # endif
 # ifdef SUNOS4
 #include <memory.h>
diff --git a/sys/unix/Makefile.src b/sys/unix/Makefile.src
index 29ad99a..7842af2 100644
--- a/sys/unix/Makefile.src
+++ b/sys/unix/Makefile.src
@@ -151,8 +151,8 @@ GNOMEINC=-I/usr/lib/glib/include -I/usr/lib/gnome-libs/include -I../win/gnome
 # flags for debugging:
 # CFLAGS = -g -I../include
 
-CFLAGS = -O -I../include
-LFLAGS = 
+#CFLAGS = -O -I../include
+#LFLAGS = 
 
 # The Qt and Be window systems are written in C++, while the rest of
 # NetHack is standard C.  If using Qt, uncomment the LINK line here to get
@@ -230,8 +230,8 @@ WINOBJ = $(WINTTYOBJ)
 # WINTTYLIB = -ltermcap
 # WINTTYLIB = -lcurses
 # WINTTYLIB = -lcurses16
-# WINTTYLIB = -lncurses
-WINTTYLIB = -ltermlib
+WINTTYLIB = -lncurses
+#WINTTYLIB = -ltermlib
 #
 # libraries for X11
 # If USE_XPM is defined in config.h, you will also need -lXpm here.
diff --git a/win/tty/termcap.c b/win/tty/termcap.c
index 706e203..dadc9a9 100644
--- a/win/tty/termcap.c
+++ b/win/tty/termcap.c
@@ -835,7 +835,7 @@ cl_eos()			/* free after Robert Viduya */
 
 #include <curses.h>
 
-#ifndef LINUX
+#if !defined(LINUX) && !defined(__APPLE__)
 extern char *tparm();
 #endif







diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/include/color.h nethack-3.4.3-menucolors/include/color.h
--- nethack-3.4.3-orig/include/color.h	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/include/color.h	2005-02-18 18:01:56.000000000 +0200
@@ -5,6 +5,12 @@
 #ifndef COLOR_H
 #define COLOR_H
 
+#ifdef MENU_COLOR
+# ifdef MENU_COLOR_REGEX
+#  include <regex.h>
+# endif
+#endif
+
 /*
  * The color scheme used is tailored for an IBM PC.  It consists of the
  * standard 8 colors, folowed by their bright counterparts.  There are
@@ -49,4 +55,20 @@
 #define DRAGON_SILVER	CLR_BRIGHT_CYAN
 #define HI_ZAP		CLR_BRIGHT_BLUE
 
+#ifdef MENU_COLOR
+struct menucoloring {
+# ifdef MENU_COLOR_REGEX
+#  ifdef MENU_COLOR_REGEX_POSIX
+    regex_t match;
+#  else
+    struct re_pattern_buffer match;
+#  endif
+# else
+    char *match;
+# endif
+    int color, attr;
+    struct menucoloring *next;
+};
+#endif /* MENU_COLOR */
+
 #endif /* COLOR_H */
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/include/config.h nethack-3.4.3-menucolors/include/config.h
--- nethack-3.4.3-orig/include/config.h	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/include/config.h	2006-09-20 23:25:49.000000000 +0300
@@ -348,6 +348,18 @@
  * bugs left here.
  */
 
+#if defined(TTY_GRAPHICS) || defined(MSWIN_GRAPHICS)
+# define MENU_COLOR
+# define MENU_COLOR_REGEX
+/*# define MENU_COLOR_REGEX_POSIX */
+/* if MENU_COLOR_REGEX is defined, use regular expressions (regex.h,
+ * GNU specific functions by default, POSIX functions with
+ * MENU_COLOR_REGEX_POSIX).
+ * otherwise use pmatch() to match menu color lines.
+ * pmatch() provides basic globbing: '*' and '?' wildcards.
+ */
+#endif
+
 /*#define GOLDOBJ */	/* Gold is kept on obj chains - Helge Hafting */
 /*#define AUTOPICKUP_EXCEPTIONS */ /* exceptions to autopickup */
 
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/include/extern.h nethack-3.4.3-menucolors/include/extern.h
--- nethack-3.4.3-orig/include/extern.h	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/include/extern.h	2005-02-18 18:01:56.000000000 +0200
@@ -1405,6 +1405,9 @@
 E int FDECL(add_autopickup_exception, (const char *));
 E void NDECL(free_autopickup_exceptions);
 #endif /* AUTOPICKUP_EXCEPTIONS */
+#ifdef MENU_COLOR
+E boolean FDECL(add_menu_coloring, (char *));
+#endif /* MENU_COLOR */
 
 /* ### pager.c ### */
 
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/include/flag.h nethack-3.4.3-menucolors/include/flag.h
--- nethack-3.4.3-orig/include/flag.h	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/include/flag.h	2005-02-18 18:01:56.000000000 +0200
@@ -183,6 +183,9 @@
 	char prevmsg_window;	/* type of old message window to use */
 	boolean  extmenu;	/* extended commands use menu interface */
 #endif
+#ifdef MENU_COLOR
+	boolean use_menu_color;	/* use color in menus; only if wc_color */
+#endif
 #ifdef MFLOPPY
 	boolean  checkspace;	/* check disk space before writing files */
 				/* (in iflags to allow restore after moving
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/README.menucolor nethack-3.4.3-menucolors/README.menucolor
--- nethack-3.4.3-orig/README.menucolor	1970-01-01 02:00:00.000000000 +0200
+++ nethack-3.4.3-menucolors/README.menucolor	2006-09-20 23:27:08.000000000 +0300
@@ -0,0 +1,106 @@
+
+   This is version 1.5 of the menucolors patch.
+
+   This patch allows the user to define in what color menus are shown.
+   For example, putting
+
+   OPTIONS=menucolors
+   MENUCOLOR=" blessed "=green
+   MENUCOLOR=" holy "=green
+   MENUCOLOR=" cursed "=red
+   MENUCOLOR=" unholy "=red
+   MENUCOLOR=" cursed .* (being worn)"=orange&underline
+
+   in the configuration file makes all known blessed items
+   show up in green, all cursed items show up in red and
+   all cursed worn items show up in orange and underlined
+   when viewing inventory.
+
+   If you have regex.h but it is not GNU (e.g. DJGPP, *BSD), uncomment
+   #define MENU_COLOR_REGEX_POSIX in include/config.h
+
+   If you do not have regex.h, comment
+   #define MENU_COLOR_REGEX out from include/config.h
+   and replace the MENUCOLOR lines in your config file with these:
+
+   MENUCOLOR="* blessed *"=green
+   MENUCOLOR="* holy *"=green
+   MENUCOLOR="* cursed *"=red
+   MENUCOLOR="* unholy *"=red
+   MENUCOLOR="* cursed * (being worn)"=orange&underline
+
+
+   Colors: black, red, green, brown, blue, magenta, cyan, gray, orange,
+           lightgreen, yellow, lightblue, lightmagenta, lightcyan, white.
+   Attributes: none, bold, dim, underline, blink, inverse.
+
+   Note that the terminal is free to interpret the attributes however
+   it wants.
+
+
+   TODO/BUGS:
+
+    o Only works with TTY and Windows GUI.
+    o You can't use '=' or '&' in the match-string.
+    o Maybe add color-field to tty_menu_item in include/wintty.h
+      (so there's no need to find the color for the line again)
+    o Guidebook is not up to date
+    o Better place to put the functions, colornames[] and attrnames[]?
+    o Some menus do not need coloring; maybe add new parameter
+      to process_menu_window()?
+
+
+   FIXES:
+
+   v1.5:
+    o Partial support for Windows GUI windowport; supports colors,
+      but not attributes.
+
+   v1.4:
+    o Option to use standard instead of GNU regex functions.
+
+   v1.3:
+    o Updated to use 3.4.3 codebase.
+    o Added a text to #version to show menucolors is compiled in.
+
+   v1.2:
+    o Updated to use 3.4.2 codebase.
+
+   v1.1:
+    o Updated to use 3.4.1 codebase.
+    o replaced USE_REGEX_MATCH with MENU_COLOR_REGEX
+
+   v1.04:
+    o Oops! 1.03 worked only on *nixes... (GNU regex.h)
+    o Compile-time option USE_REGEX_MATCH: if it's defined, use regex,
+      otherwise use globbing. ('?' and '*' wildcards)
+
+   v1.03:
+
+    o Now using Nethack 3.4.0 codebase
+    o Compile-time option MENU_COLOR
+    o Strings match using regular expressions instead of globbing
+    o You can use attribute with color (attr must come after '&')
+    o Use ``MENUCOLOR="foo"=color'' instead of ``OPTIONS=menucolor=...''
+      (Both work, but OPTIONS complains if you define menucolor
+      more than once)
+
+   v1.02:
+
+    o Should now work with OS/2, thanks to Jukka Lahtinen
+    o Strings match now using simple globbing. ('?' and '*' wildcards)
+
+   v1.01:
+
+    o Moved 'menucolors' boolean option, so now the options-menu
+      is in alphabetical order.
+    o Fixed 'menucolor' description in dat/opthelp.
+    o menu_colorings is now initialized to null in src/decl.c.
+
+   v1.0:
+
+    o Initial release
+
+--
+ Pasi Kallinen
+ paxed@alt.org
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/src/decl.c nethack-3.4.3-menucolors/src/decl.c
--- nethack-3.4.3-orig/src/decl.c	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/src/decl.c	2005-02-18 18:01:56.000000000 +0200
@@ -235,6 +235,10 @@
 	"white",		/* CLR_WHITE */
 };
 
+#ifdef MENU_COLOR
+struct menucoloring *menu_colorings = 0;
+#endif
+
 struct c_common_strings c_common_strings = {
 	"Nothing happens.",		"That's enough tries!",
 	"That is a silly thing to %s.",	"shudder for a moment.",
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/src/files.c nethack-3.4.3-menucolors/src/files.c
--- nethack-3.4.3-orig/src/files.c	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/src/files.c	2005-02-18 18:01:56.000000000 +0200
@@ -1794,6 +1794,10 @@
 	} else if (match_varname(buf, "BOULDER", 3)) {
 	    (void) get_uchars(fp, buf, bufp, &iflags.bouldersym, TRUE,
 			      1, "BOULDER");
+	} else if (match_varname(buf, "MENUCOLOR", 9)) {
+#ifdef MENU_COLOR
+	    (void) add_menu_coloring(bufp);
+#endif
 	} else if (match_varname(buf, "GRAPHICS", 4)) {
 	    len = get_uchars(fp, buf, bufp, translate, FALSE,
 			     MAXPCHARS, "GRAPHICS");
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/src/options.c nethack-3.4.3-menucolors/src/options.c
--- nethack-3.4.3-orig/src/options.c	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/src/options.c	2005-02-18 18:01:56.000000000 +0200
@@ -125,6 +125,15 @@
 #else
 	{"mail", (boolean *)0, TRUE, SET_IN_FILE},
 #endif
+#ifdef MENU_COLOR
+# ifdef MICRO
+	{"menucolors", &iflags.use_menu_color, TRUE,  SET_IN_GAME},
+# else
+	{"menucolors", &iflags.use_menu_color, FALSE, SET_IN_GAME},
+# endif
+#else
+	{"menucolors", (boolean *)0, FALSE, SET_IN_GAME},
+#endif
 #ifdef WIZARD
 	/* for menu debugging only*/
 	{"menu_tab_sep", &iflags.menu_tab_sep, FALSE, SET_IN_GAME},
@@ -246,6 +255,7 @@
 	{ "horsename", "the name of your (first) horse (e.g., horsename:Silver)",
 						PL_PSIZ, DISP_IN_GAME },
 	{ "map_mode", "map display mode under Windows", 20, DISP_IN_GAME },	/*WC*/
+	{ "menucolor", "set menu colors", PL_PSIZ, SET_IN_FILE },
 	{ "menustyle", "user interface for object selection",
 						MENUTYPELEN, SET_IN_GAME },
 	{ "menu_deselect_all", "deselect all items in a menu", 4, SET_IN_FILE },
@@ -964,6 +974,133 @@
 	}
 }
 
+#ifdef MENU_COLOR
+extern struct menucoloring *menu_colorings;
+
+static const struct {
+   const char *name;
+   const int color;
+} colornames[] = {
+   {"black", CLR_BLACK},
+   {"red", CLR_RED},
+   {"green", CLR_GREEN},
+   {"brown", CLR_BROWN},
+   {"blue", CLR_BLUE},
+   {"magenta", CLR_MAGENTA},
+   {"cyan", CLR_CYAN},
+   {"gray", CLR_GRAY},
+   {"orange", CLR_ORANGE},
+   {"lightgreen", CLR_BRIGHT_GREEN},
+   {"yellow", CLR_YELLOW},
+   {"lightblue", CLR_BRIGHT_BLUE},
+   {"lightmagenta", CLR_BRIGHT_MAGENTA},
+   {"lightcyan", CLR_BRIGHT_CYAN},
+   {"white", CLR_WHITE}
+};
+
+static const struct {
+   const char *name;
+   const int attr;
+} attrnames[] = {
+     {"none", ATR_NONE},
+     {"bold", ATR_BOLD},
+     {"dim", ATR_DIM},
+     {"underline", ATR_ULINE},
+     {"blink", ATR_BLINK},
+     {"inverse", ATR_INVERSE}
+
+};
+
+/* parse '"regex_string"=color&attr' and add it to menucoloring */
+boolean
+add_menu_coloring(str)
+char *str;
+{
+    int i, c = NO_COLOR, a = ATR_NONE;
+    struct menucoloring *tmp;
+    char *tmps, *cs = strchr(str, '=');
+#ifdef MENU_COLOR_REGEX_POSIX
+    int errnum;
+    char errbuf[80];
+#endif
+    const char *err = (char *)0;
+
+    if (!cs || !str) return FALSE;
+
+    tmps = cs;
+    tmps++;
+    while (*tmps && isspace(*tmps)) tmps++;
+
+    for (i = 0; i < SIZE(colornames); i++)
+	if (strstri(tmps, colornames[i].name) == tmps) {
+	    c = colornames[i].color;
+	    break;
+	}
+    if ((i == SIZE(colornames)) && (*tmps >= '0' && *tmps <='9'))
+	c = atoi(tmps);
+
+    if (c > 15) return FALSE;
+
+    tmps = strchr(str, '&');
+    if (tmps) {
+	tmps++;
+	while (*tmps && isspace(*tmps)) tmps++;
+	for (i = 0; i < SIZE(attrnames); i++)
+	    if (strstri(tmps, attrnames[i].name) == tmps) {
+		a = attrnames[i].attr;
+		break;
+	    }
+	if ((i == SIZE(attrnames)) && (*tmps >= '0' && *tmps <='9'))
+	    a = atoi(tmps);
+    }
+
+    *cs = '\0';
+    tmps = str;
+    if ((*tmps == '"') || (*tmps == '\'')) {
+	cs--;
+	while (isspace(*cs)) cs--;
+	if (*cs == *tmps) {
+	    *cs = '\0';
+	    tmps++;
+	}
+    }
+
+    tmp = (struct menucoloring *)alloc(sizeof(struct menucoloring));
+#ifdef MENU_COLOR_REGEX
+#ifdef MENU_COLOR_REGEX_POSIX
+    errnum = regcomp(&tmp->match, tmps, REG_EXTENDED | REG_NOSUB);
+    if (errnum != 0)
+    {
+	regerror(errnum, &tmp->match, errbuf, sizeof(errbuf));
+	err = errbuf;
+    }
+#else
+    tmp->match.translate = 0;
+    tmp->match.fastmap = 0;
+    tmp->match.buffer = 0;
+    tmp->match.allocated = 0;
+    tmp->match.regs_allocated = REGS_FIXED;
+    err = re_compile_pattern(tmps, strlen(tmps), &tmp->match);
+#endif
+#else
+    tmp->match = (char *)alloc(strlen(tmps)+1);
+    (void) memcpy((genericptr_t)tmp->match, (genericptr_t)tmps, strlen(tmps)+1);
+#endif
+    if (err) {
+	raw_printf("\nMenucolor regex error: %s\n", err);
+	wait_synch();
+	free(tmp);
+	return FALSE;
+    } else {
+	tmp->next = menu_colorings;
+	tmp->color = c;
+	tmp->attr = a;
+	menu_colorings = tmp;
+	return TRUE;
+    }
+}
+#endif /* MENU_COLOR */
+
 void
 parseoptions(opts, tinitial, tfrom_file)
 register char *opts;
@@ -1133,6 +1270,18 @@
 		return;
 	}
 
+	/* menucolor:"regex_string"=color */
+	fullname = "menucolor";
+	if (match_optname(opts, fullname, 9, TRUE)) {
+#ifdef MENU_COLOR
+	    if (negated) bad_negation(fullname, FALSE);
+	    else if ((op = string_for_env_opt(fullname, opts, FALSE)) != 0)
+		if (!add_menu_coloring(op))
+		    badoption(opts);
+#endif
+	    return;
+	}
+
 	fullname = "msghistory";
 	if (match_optname(opts, fullname, 3, TRUE)) {
 		op = string_for_env_opt(fullname, opts, negated);
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/src/save.c nethack-3.4.3-menucolors/src/save.c
--- nethack-3.4.3-orig/src/save.c	2006-08-08 23:07:19.000000000 +0300
+++ nethack-3.4.3-menucolors/src/save.c	2005-02-18 18:01:56.000000000 +0200
@@ -48,6 +48,10 @@
 #define HUP
 #endif
 
+#ifdef MENU_COLOR
+extern struct menucoloring *menu_colorings;
+#endif
+
 /* need to preserve these during save to avoid accessing freed memory */
 static unsigned ustuck_id = 0, usteed_id = 0;
 
@@ -953,12 +957,34 @@
 	return;
 }
 
+#ifdef MENU_COLOR
+void
+free_menu_coloring()
+{
+    struct menucoloring *tmp = menu_colorings;
+
+    while (tmp) {
+	struct menucoloring *tmp2 = tmp->next;
+# ifdef MENU_COLOR_REGEX
+	(void) regfree(&tmp->match);
+# else
+	free(tmp->match);
+# endif
+	free(tmp);
+	tmp = tmp2;
+    }
+}
+#endif /* MENU_COLOR */
+
 void
 freedynamicdata()
 {
 	unload_qtlist();
 	free_invbuf();	/* let_to_name (invent.c) */
 	free_youbuf();	/* You_buf,&c (pline.c) */
+#ifdef MENU_COLOR
+	free_menu_coloring();
+#endif
 	tmp_at(DISP_FREEMEM, 0);	/* temporary display effects */
 #ifdef FREE_ALL_MEMORY
 # define freeobjchn(X)	(saveobjchn(0, X, FREE_SAVE),  X = 0)
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/util/makedefs.c nethack-3.4.3-menucolors/util/makedefs.c
--- nethack-3.4.3-orig/util/makedefs.c	2006-08-08 23:07:20.000000000 +0300
+++ nethack-3.4.3-menucolors/util/makedefs.c	2005-02-18 18:01:56.000000000 +0200
@@ -679,6 +679,13 @@
 #ifdef MAIL
 		"mail daemon",
 #endif
+#ifdef MENU_COLOR
+# ifdef MENU_COLOR_REGEX
+		"menu colors via regular expressions",
+# else
+		"menu colors via pmatch",
+# endif
+#endif
 #ifdef GNUDOS
 		"MSDOS protected mode",
 #endif
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/win/tty/wintty.c nethack-3.4.3-menucolors/win/tty/wintty.c
--- nethack-3.4.3-orig/win/tty/wintty.c	2006-08-08 23:07:20.000000000 +0300
+++ nethack-3.4.3-menucolors/win/tty/wintty.c	2005-02-18 18:01:57.000000000 +0200
@@ -125,6 +125,10 @@
 static char winpanicstr[] = "Bad window id %d";
 char defmorestr[] = "--More--";
 
+#ifdef MENU_COLOR
+extern struct menucoloring *menu_colorings;
+#endif
+
 #ifdef CLIPPING
 # if defined(USE_TILES) && defined(MSDOS)
 boolean clipping = FALSE;	/* clipping on? */
@@ -1128,6 +1132,32 @@
     }
 }
 
+#ifdef MENU_COLOR
+STATIC_OVL boolean
+get_menu_coloring(str, color, attr)
+char *str;
+int *color, *attr;
+{
+    struct menucoloring *tmpmc;
+    if (iflags.use_menu_color)
+	for (tmpmc = menu_colorings; tmpmc; tmpmc = tmpmc->next)
+# ifdef MENU_COLOR_REGEX
+#  ifdef MENU_COLOR_REGEX_POSIX
+	    if (regexec(&tmpmc->match, str, 0, NULL, 0) == 0) {
+#  else
+	    if (re_search(&tmpmc->match, str, strlen(str), 0, 9999, 0) >= 0) {
+#  endif
+# else
+	    if (pmatch(tmpmc->match, str)) {
+# endif
+		*color = tmpmc->color;
+		*attr = tmpmc->attr;
+		return TRUE;
+	    }
+    return FALSE;
+}
+#endif /* MENU_COLOR */
+
 STATIC_OVL void
 process_menu_window(window, cw)
 winid window;
@@ -1204,6 +1234,10 @@
 		for (page_lines = 0, curr = page_start;
 			curr != page_end;
 			page_lines++, curr = curr->next) {
+#ifdef MENU_COLOR
+		    int color = NO_COLOR, attr = ATR_NONE;
+		    boolean menucolr = FALSE;
+#endif
 		    if (curr->selector)
 			*rp++ = curr->selector;
 
@@ -1219,6 +1253,13 @@
 		     * actually output the character.  We're faster doing
 		     * this.
 		     */
+#ifdef MENU_COLOR
+		   if (iflags.use_menu_color &&
+		       (menucolr = get_menu_coloring(curr->str, &color,&attr))) {
+		       term_start_attr(attr);
+		       if (color != NO_COLOR) term_start_color(color);
+		   } else
+#endif
 		    term_start_attr(curr->attr);
 		    for (n = 0, cp = curr->str;
 #ifndef WIN32CON
@@ -1236,6 +1277,12 @@
 				(void) putchar('#'); /* count selected */
 			} else
 			    (void) putchar(*cp);
+#ifdef MENU_COLOR
+		   if (iflags.use_menu_color && menucolr) {
+		       if (color != NO_COLOR) term_end_color();
+		       term_end_attr(attr);
+		   } else
+#endif
 		    term_end_attr(curr->attr);
 		}
 	    } else {
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/win/win32/mhmenu.c nethack-3.4.3-menucolors/win/win32/mhmenu.c
--- nethack-3.4.3-orig/win/win32/mhmenu.c	2006-08-08 23:07:20.000000000 +0300
+++ nethack-3.4.3-menucolors/win/win32/mhmenu.c	2006-09-20 23:24:21.000000000 +0300
@@ -63,6 +63,10 @@
 
 extern short glyph2tile[];
 
+#ifdef MENU_COLOR
+extern struct menucoloring *menu_colorings;
+#endif
+
 static WNDPROC wndProcListViewOrig = NULL;
 static WNDPROC editControlWndProc = NULL;
 
@@ -83,6 +87,58 @@
 static void reset_menu_count(HWND hwndList, PNHMenuWindow data);
 static BOOL onListChar(HWND hWnd, HWND hwndList, WORD ch);
 
+#ifdef MENU_COLOR
+/* FIXME: nhcolor_to_RGB copied from mhmap.c */
+/* map nethack color to RGB */
+COLORREF nhcolor_to_RGB(int c)
+{
+	switch(c) {
+	case CLR_BLACK:			return RGB(0x55, 0x55, 0x55);
+	case CLR_RED:			return RGB(0xFF, 0x00, 0x00);
+	case CLR_GREEN:			return RGB(0x00, 0x80, 0x00);
+	case CLR_BROWN:			return RGB(0xA5, 0x2A, 0x2A);
+	case CLR_BLUE:			return RGB(0x00, 0x00, 0xFF);
+	case CLR_MAGENTA:		return RGB(0xFF, 0x00, 0xFF);
+	case CLR_CYAN:			return RGB(0x00, 0xFF, 0xFF);
+	case CLR_GRAY:			return RGB(0xC0, 0xC0, 0xC0);
+	case NO_COLOR:			return RGB(0xFF, 0xFF, 0xFF);
+	case CLR_ORANGE:		return RGB(0xFF, 0xA5, 0x00);
+	case CLR_BRIGHT_GREEN:		return RGB(0x00, 0xFF, 0x00);
+	case CLR_YELLOW:		return RGB(0xFF, 0xFF, 0x00);
+	case CLR_BRIGHT_BLUE:		return RGB(0x00, 0xC0, 0xFF);
+	case CLR_BRIGHT_MAGENTA: 	return RGB(0xFF, 0x80, 0xFF);
+	case CLR_BRIGHT_CYAN:		return RGB(0x80, 0xFF, 0xFF);	/* something close to aquamarine */
+	case CLR_WHITE:			return RGB(0xFF, 0xFF, 0xFF);
+	default:			return RGB(0x00, 0x00, 0x00);	/* black */
+	}
+}
+
+
+STATIC_OVL boolean
+get_menu_coloring(str, color, attr)
+char *str;
+int *color, *attr;
+{
+    struct menucoloring *tmpmc;
+    if (iflags.use_menu_color)
+	for (tmpmc = menu_colorings; tmpmc; tmpmc = tmpmc->next)
+# ifdef MENU_COLOR_REGEX
+#  ifdef MENU_COLOR_REGEX_POSIX
+	    if (regexec(&tmpmc->match, str, 0, NULL, 0) == 0) {
+#  else
+	    if (re_search(&tmpmc->match, str, strlen(str), 0, 9999, 0) >= 0) {
+#  endif
+# else
+	    if (pmatch(tmpmc->match, str)) {
+# endif
+		*color = tmpmc->color;
+		*attr = tmpmc->attr;
+		return TRUE;
+	    }
+    return FALSE;
+}
+#endif /* MENU_COLOR */
+
 /*-----------------------------------------------------------------------------*/
 HWND mswin_init_menu_window (int type) {
 	HWND ret;
@@ -767,6 +823,11 @@
 	char *p, *p1;
 	int column;
 
+#ifdef MENU_COLOR
+	int color = NO_COLOR, attr;
+	boolean menucolr = FALSE;
+#endif
+
 	lpdis = (LPDRAWITEMSTRUCT) lParam; 
 
     /* If there are no list box items, skip this message. */
@@ -813,6 +874,15 @@
 			buf[0] = item->accelerator;
 			buf[1] = '\x0';
 
+#ifdef MENU_COLOR
+			if (iflags.use_menu_color &&
+			    (menucolr = get_menu_coloring(item->str, &color,&attr))) {
+			    /* TODO: use attr too */
+			    if (color != NO_COLOR)
+				SetTextColor(lpdis->hDC, nhcolor_to_RGB(color));
+			}
+#endif
+
 			SetRect( &drawRect, x, lpdis->rcItem.top, lpdis->rcItem.right, lpdis->rcItem.bottom );
 			DrawText(lpdis->hDC, NH_A2W(buf, wbuf, 2), 1, &drawRect, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
 		}





diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/include/flag.h nethack-3.4.3-showbuc/include/flag.h
--- nethack-3.4.3-orig/include/flag.h	2003-12-08 01:39:13.000000000 +0200
+++ nethack-3.4.3-showbuc/include/flag.h	2006-05-15 22:35:10.000000000 +0300
@@ -264,6 +264,7 @@
 	boolean wc2_softkeyboard;	/* use software keyboard */
 	boolean wc2_wraptext;		/* wrap text */
 
+	boolean show_buc;	/* always show BUC status */
 	boolean  cmdassist;	/* provide detailed assistance for some commands */
 	boolean	 obsolete;	/* obsolete options can point at this, it isn't used */
 	/* Items which belong in flags, but are here to allow save compatibility */
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/src/objnam.c nethack-3.4.3-showbuc/src/objnam.c
--- nethack-3.4.3-orig/src/objnam.c	2003-12-08 01:39:13.000000000 +0200
+++ nethack-3.4.3-showbuc/src/objnam.c	2006-05-15 22:40:00.000000000 +0300
@@ -600,7 +600,7 @@
 		Strcat(prefix, "cursed ");
 	    else if (obj->blessed)
 		Strcat(prefix, "blessed ");
-	    else if ((!obj->known || !objects[obj->otyp].oc_charged ||
+	    else if (iflags.show_buc || (!obj->known || !objects[obj->otyp].oc_charged ||
 		      (obj->oclass == ARMOR_CLASS ||
 		       obj->oclass == RING_CLASS))
 		/* For most items with charges or +/-, if you know how many
diff -Nurd --exclude-from=diff_ignore_files.txt nethack-3.4.3-orig/src/options.c nethack-3.4.3-showbuc/src/options.c
--- nethack-3.4.3-orig/src/options.c	2003-12-08 01:39:13.000000000 +0200
+++ nethack-3.4.3-showbuc/src/options.c	2006-05-15 22:40:07.000000000 +0300
@@ -165,6 +165,7 @@
 #else
 	{"showexp", (boolean *)0, FALSE, SET_IN_FILE},
 #endif
+	{"showbuc", &iflags.show_buc, FALSE, SET_IN_GAME},
 	{"showrace", &iflags.showrace, FALSE, SET_IN_GAME},
 #ifdef SCORE_ON_BOTL
 	{"showscore", &flags.showscore, FALSE, SET_IN_GAME},





diff -Nurdp nethack-3.4.3/include/color.h nethack-3.4.3.statuscolors/include/color.h
--- nethack-3.4.3/include/color.h	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/include/color.h	2006-11-11 19:17:57.000000000 -0800
@@ -49,4 +49,23 @@
 #define DRAGON_SILVER	CLR_BRIGHT_CYAN
 #define HI_ZAP		CLR_BRIGHT_BLUE
 
+#ifdef STATUS_COLORS
+struct color_option {
+    int color;
+    int attr_bits;
+};
+
+struct percent_color_option {
+	int percentage;
+	struct color_option color_option;
+	const struct percent_color_option *next;
+};
+
+struct text_color_option {
+	const char *text;
+	struct color_option color_option;
+	const struct text_color_option *next;
+};
+#endif
+
 #endif /* COLOR_H */
diff -Nurdp nethack-3.4.3/include/config.h nethack-3.4.3.statuscolors/include/config.h
--- nethack-3.4.3/include/config.h	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/include/config.h	2006-11-11 19:17:57.000000000 -0800
@@ -348,6 +348,8 @@ typedef unsigned char	uchar;
  * bugs left here.
  */
 
+#define STATUS_COLORS
+
 /*#define GOLDOBJ */	/* Gold is kept on obj chains - Helge Hafting */
 /*#define AUTOPICKUP_EXCEPTIONS */ /* exceptions to autopickup */
 
diff -Nurdp nethack-3.4.3/include/flag.h nethack-3.4.3.statuscolors/include/flag.h
--- nethack-3.4.3/include/flag.h	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/include/flag.h	2006-11-11 19:17:57.000000000 -0800
@@ -183,6 +183,9 @@ struct instance_flags {
 	char prevmsg_window;	/* type of old message window to use */
 	boolean  extmenu;	/* extended commands use menu interface */
 #endif
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	boolean use_status_colors; /* use color in status line; only if wc_color */
+#endif
 #ifdef MFLOPPY
 	boolean  checkspace;	/* check disk space before writing files */
 				/* (in iflags to allow restore after moving
diff -Nurdp nethack-3.4.3/README.statuscolors nethack-3.4.3.statuscolors/README.statuscolors
--- nethack-3.4.3/README.statuscolors	1969-12-31 16:00:00.000000000 -0800
+++ nethack-3.4.3.statuscolors/README.statuscolors	2006-11-11 20:10:53.000000000 -0800
@@ -0,0 +1,62 @@
+Statuscolors is a patch for Nethack (version 3.4.3) that attempts to generalize
+the hpmon patch to be more like the menucolor patch. As of v1.2, the
+statuscolors patch may be applied after the menucolor patch (but not before
+it). Unlike menucolor, it does not use regexps. Instead, it provides the
+following options:
+
+To enable statuscolors:
+    OPTIONS=statuscolors
+
+To specify statuscolor options, write:
+    STATUSCOLOR=<option>,<option>
+
+Numeric options have the format <field>%<max-percent>:<color-option>. For
+example:
+    STATUSCOLOR=hp%15:red&bold,pw%100=green
+
+Text options have the format <text>:<color-option>. Text is case-insensitive.
+For example:
+    STATUSCOLOR=hallu:orange,foodpois:red&inverse&blink
+
+A color option is a <color> followed by an optional sequence of &<attr>. Color
+and attribute names are case insensitive. Valid colors are:
+    black blue brown cyan gray green lightblue lightcyan lightgreen
+    lightmagenta magenta none orange red white yellow
+
+Valid attributes are:
+    blink bold dim inverse none underline
+
+A reasonable set of defaults might be:
+    # HP
+    STATUSCOLOR=hp%100=green,hp%66=yellow,hp%50=orange
+    STATUSCOLOR=hp%33=red&bold,hp%15:red&inverse,hp%0:red&inverse&blink
+    # Pw
+    STATUSCOLOR=pw%100=green,pw%66=yellow,pw%50:orange,pw%33=red&bold
+    # Carry
+    STATUSCOLOR=burdened:yellow,stressed:orange,strained:red&bold
+    STATUSCOLOR=overtaxed:red&inverse,overloaded:red&inverse&blink
+    # Hunger
+    STATUSCOLOR=satiated:yellow,hungry:orange,weak:red&bold
+    STATUSCOLOR=fainting:red&inverse,fainted:red&inverse&blink
+    # Mental
+    STATUSCOLOR=hallu:yellow,conf:orange,stun:red&bold
+    # Health
+    STATUSCOLOR=ill:red&inverse,foodpois:red&inverse,slime:red&inverse
+    # Other
+    STATUSCOLOR=held:red&inverse,blind:red&inverse
+
+Changelog:
+
+    v1.2:
+      - Menucolor compatibility.
+
+    v1.1:
+      - Fixed several shameful bugs.
+
+    v1.0:
+      - Initial release.
+
+---
+Shachaf & Oren Ben-Kiki
+shachaf+nethack@gmail.com
+nethack-oren@ben-kiki.org
diff -Nurdp nethack-3.4.3/src/botl.c nethack-3.4.3.statuscolors/src/botl.c
--- nethack-3.4.3/src/botl.c	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/src/botl.c	2006-11-11 19:17:57.000000000 -0800
@@ -34,6 +34,106 @@ STATIC_DCL void NDECL(bot2);
 #define MAXCO (COLNO+20)
 #endif
 
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+
+extern const struct percent_color_option *hp_colors;
+extern const struct percent_color_option *pw_colors;
+extern const struct text_color_option *text_colors;
+
+struct color_option
+text_color_of(text, color_options)
+const char *text;
+const struct text_color_option *color_options;
+{
+	if (color_options == NULL) {
+		struct color_option result = {NO_COLOR, 0};
+		return result;
+	}
+	if (strstri(color_options->text, text)
+	 || strstri(text, color_options->text))
+		return color_options->color_option;
+	return text_color_of(text, color_options->next);
+}
+
+struct color_option
+percentage_color_of(value, max, color_options)
+int value, max;
+const struct percent_color_option *color_options;
+{
+	if (color_options == NULL) {
+		struct color_option result = {NO_COLOR, 0};
+		return result;
+	}
+	if (100 * value <= color_options->percentage * max)
+		return color_options->color_option;
+	return percentage_color_of(value, max, color_options->next);
+}
+
+void
+start_color_option(color_option)
+struct color_option color_option;
+{
+	int i;
+	if (color_option.color != NO_COLOR)
+		term_start_color(color_option.color);
+	for (i = 0; (1 << i) <= color_option.attr_bits; ++i)
+		if (i != ATR_NONE && color_option.attr_bits & (1 << i))
+			term_start_attr(i);
+}
+
+void
+end_color_option(color_option)
+struct color_option color_option;
+{
+	int i;
+	if (color_option.color != NO_COLOR)
+		term_end_color(color_option.color);
+	for (i = 0; (1 << i) <= color_option.attr_bits; ++i)
+		if (i != ATR_NONE && color_option.attr_bits & (1 << i))
+			term_end_attr(i);
+}
+
+void
+apply_color_option(color_option, newbot2)
+struct color_option color_option;
+const char *newbot2;
+{
+	if (!iflags.use_status_colors) return;
+	curs(WIN_STATUS, 1, 1);
+	start_color_option(color_option);
+	putstr(WIN_STATUS, 0, newbot2);
+	end_color_option(color_option);
+}
+
+void
+add_colored_text(text, newbot2)
+const char *text;
+char *newbot2;
+{
+	char *nb;
+	struct color_option color_option;
+
+	if (*text == '\0') return;
+
+	if (!iflags.use_status_colors) {
+		Sprintf(nb = eos(newbot2), " %s", text);
+                return;
+        }
+
+	Strcat(nb = eos(newbot2), " ");
+	curs(WIN_STATUS, 1, 1);
+	putstr(WIN_STATUS, 0, newbot2);
+
+	Strcat(nb = eos(nb), text);
+	curs(WIN_STATUS, 1, 1);
+       	color_option = text_color_of(text, text_colors);
+	start_color_option(color_option);
+	putstr(WIN_STATUS, 0, newbot2);
+	end_color_option(color_option);
+}
+
+#endif
+
 #ifndef OVLB
 STATIC_DCL int mrank_sz;
 #else /* OVLB */
@@ -249,21 +349,46 @@ bot2()
 	register char *nb;
 	int hp, hpmax;
 	int cap = near_capacity();
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	struct color_option color_option;
+	int save_botlx = flags.botlx;
+#endif
 
 	hp = Upolyd ? u.mh : u.uhp;
 	hpmax = Upolyd ? u.mhmax : u.uhpmax;
 
 	if(hp < 0) hp = 0;
 	(void) describe_level(newbot2);
-	Sprintf(nb = eos(newbot2),
-		"%c:%-2ld HP:%d(%d) Pw:%d(%d) AC:%-2d", oc_syms[COIN_CLASS],
+	Sprintf(nb = eos(newbot2), "%c:%-2ld", oc_syms[COIN_CLASS],
 #ifndef GOLDOBJ
-		u.ugold,
+		u.ugold
 #else
-		money_cnt(invent),
+		money_cnt(invent)
 #endif
-		hp, hpmax, u.uen, u.uenmax, u.uac);
+	       );
+
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	Strcat(nb = eos(newbot2), " HP:");
+	curs(WIN_STATUS, 1, 1);
+	putstr(WIN_STATUS, 0, newbot2);
+	flags.botlx = 0;
 
+	Sprintf(nb = eos(nb), "%d(%d)", hp, hpmax);
+	apply_color_option(percentage_color_of(hp, hpmax, hp_colors), newbot2);
+#else
+	Sprintf(nb = eos(nb), " HP:%d(%d)", hp, hpmax);
+#endif
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	Strcat(nb = eos(nb), " Pw:");
+	curs(WIN_STATUS, 1, 1);
+	putstr(WIN_STATUS, 0, newbot2);
+
+	Sprintf(nb = eos(nb), "%d(%d)", u.uen, u.uenmax);
+	apply_color_option(percentage_color_of(u.uen, u.uenmax, pw_colors), newbot2);
+#else
+	Sprintf(nb = eos(nb), " Pw:%d(%d)", u.uen, u.uenmax);
+#endif
+	Sprintf(nb = eos(nb), " AC:%-2d", u.uac);
 	if (Upolyd)
 		Sprintf(nb = eos(nb), " HD:%d", mons[u.umonnum].mlevel);
 #ifdef EXP_ON_BOTL
@@ -275,25 +400,65 @@ bot2()
 
 	if(flags.time)
 	    Sprintf(nb = eos(nb), " T:%ld", moves);
-	if(strcmp(hu_stat[u.uhs], "        ")) {
-		Sprintf(nb = eos(nb), " ");
-		Strcat(newbot2, hu_stat[u.uhs]);
-	}
-	if(Confusion)	   Sprintf(nb = eos(nb), " Conf");
+	if(strcmp(hu_stat[u.uhs], "        "))
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	     	add_colored_text(hu_stat[u.uhs], newbot2);
+#else
+		Sprintf(nb = eos(nb), " %s", hu_stat[u.uhs]);
+#endif
+	if(Confusion)
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	     	add_colored_text("Conf", newbot2);
+#else
+		Strcat(nb = eos(nb), " Conf");
+#endif
 	if(Sick) {
 		if (u.usick_type & SICK_VOMITABLE)
-			   Sprintf(nb = eos(nb), " FoodPois");
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+			add_colored_text("FoodPois", newbot2);
+#else
+			Strcat(nb = eos(nb), " FoodPois");
+#endif
 		if (u.usick_type & SICK_NONVOMITABLE)
-			   Sprintf(nb = eos(nb), " Ill");
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+			add_colored_text("Ill", newbot2);
+#else
+			Strcat(nb = eos(nb), " Ill");
+#endif
 	}
-	if(Blind)	   Sprintf(nb = eos(nb), " Blind");
-	if(Stunned)	   Sprintf(nb = eos(nb), " Stun");
-	if(Hallucination)  Sprintf(nb = eos(nb), " Hallu");
-	if(Slimed)         Sprintf(nb = eos(nb), " Slime");
+	if(Blind)
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	     	add_colored_text("Blind", newbot2);
+#else
+		Strcat(nb = eos(nb), " Blind");
+#endif
+	if(Stunned)
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	     	add_colored_text("Stun", newbot2);
+#else
+		Strcat(nb = eos(nb), " Stun");
+#endif
+	if(Hallucination)
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	     	add_colored_text("Hallu", newbot2);
+#else
+		Strcat(nb = eos(nb), " Hallu");
+#endif
+	if(Slimed)
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	     	add_colored_text("Slime", newbot2);
+#else
+		Strcat(nb = eos(nb), " Slime");
+#endif
 	if(cap > UNENCUMBERED)
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+		add_colored_text(enc_stat[cap], newbot2);
+#else
 		Sprintf(nb = eos(nb), " %s", enc_stat[cap]);
+#endif
 	curs(WIN_STATUS, 1, 1);
 	putstr(WIN_STATUS, 0, newbot2);
+	flags.botlx = save_botlx;
 }
 
 void
diff -Nurdp nethack-3.4.3/src/files.c nethack-3.4.3.statuscolors/src/files.c
--- nethack-3.4.3/src/files.c	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/src/files.c	2006-11-11 19:46:27.000000000 -0800
@@ -1797,6 +1797,10 @@ char		*tmp_levels;
 	} else if (match_varname(buf, "GRAPHICS", 4)) {
 	    len = get_uchars(fp, buf, bufp, translate, FALSE,
 			     MAXPCHARS, "GRAPHICS");
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	} else if (match_varname(buf, "STATUSCOLOR", 11)) {
+	    (void) parse_status_color_options(bufp);
+#endif
 	    assign_graphics(translate, len, MAXPCHARS, 0);
 	} else if (match_varname(buf, "DUNGEON", 4)) {
 	    len = get_uchars(fp, buf, bufp, translate, FALSE,
diff -Nurdp nethack-3.4.3/src/options.c nethack-3.4.3.statuscolors/src/options.c
--- nethack-3.4.3/src/options.c	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/src/options.c	2006-11-11 19:19:30.000000000 -0800
@@ -125,6 +125,11 @@ static struct Bool_Opt
 #else
 	{"mail", (boolean *)0, TRUE, SET_IN_FILE},
 #endif
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	{"statuscolors", &iflags.use_status_colors, TRUE, SET_IN_GAME},
+#else
+	{"statuscolors", (boolean *)0, TRUE, SET_IN_GAME},
+#endif
 #ifdef WIZARD
 	/* for menu debugging only*/
 	{"menu_tab_sep", &iflags.menu_tab_sep, FALSE, SET_IN_GAME},
@@ -309,6 +314,7 @@ static struct Comp_Opt
 #ifdef MSDOS
 	{ "soundcard", "type of sound card to use", 20, SET_IN_FILE },
 #endif
+	{ "statuscolor", "set status colors", PL_PSIZ, SET_IN_FILE },
 	{ "suppress_alert", "suppress alerts about version-specific features",
 						8, SET_IN_GAME },
 	{ "tile_width", "width of tiles", 20, DISP_IN_GAME},	/*WC*/
@@ -964,6 +970,165 @@ int bool_or_comp;	/* 0 == boolean option
 	}
 }
 
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+
+struct name_value {
+	char *name;
+	int value;
+};
+
+const struct name_value status_colornames[] = {
+	{ "black",	CLR_BLACK },
+	{ "red",	CLR_RED },
+	{ "green",	CLR_GREEN },
+	{ "brown",	CLR_BROWN },
+	{ "blue",	CLR_BLUE },
+	{ "magenta",	CLR_MAGENTA },
+	{ "cyan",	CLR_CYAN },
+	{ "gray",	CLR_GRAY },
+	{ "orange",	CLR_ORANGE },
+	{ "lightgreen",	CLR_BRIGHT_GREEN },
+	{ "yellow",	CLR_YELLOW },
+	{ "lightblue",	CLR_BRIGHT_BLUE },
+	{ "lightmagenta", CLR_BRIGHT_MAGENTA },
+	{ "lightcyan",	CLR_BRIGHT_CYAN },
+	{ "white",	CLR_WHITE },
+	{ NULL,		-1 }
+};
+
+const struct name_value status_attrnames[] = {
+	 { "none",	ATR_NONE },
+	 { "bold",	ATR_BOLD },
+	 { "dim",	ATR_DIM },
+	 { "underline",	ATR_ULINE },
+	 { "blink",	ATR_BLINK },
+	 { "inverse",	ATR_INVERSE },
+	 { NULL,	-1 }
+};
+
+int
+value_of_name(name, name_values)
+const char *name;
+const struct name_value *name_values;
+{
+	while (name_values->name && !strstri(name_values->name, name))
+		++name_values;
+	return name_values->value;
+}
+
+struct color_option
+parse_color_option(start)
+char *start;
+{
+	struct color_option result = {NO_COLOR, 0};
+	char last;
+	char *end;
+	int attr;
+
+	for (end = start; *end != '&' && *end != '\0'; ++end);
+	last = *end;
+	*end = '\0';
+	result.color = value_of_name(start, status_colornames);
+
+	while (last == '&') {
+		for (start = ++end; *end != '&' && *end != '\0'; ++end);
+		last = *end;
+		*end = '\0';
+		attr = value_of_name(start, status_attrnames);
+		if (attr >= 0)
+			result.attr_bits |= 1 << attr;
+	}
+
+	return result;
+}
+
+const struct percent_color_option *hp_colors = NULL;
+const struct percent_color_option *pw_colors = NULL;
+const struct text_color_option *text_colors = NULL;
+
+struct percent_color_option *
+add_percent_option(new_option, list_head)
+struct percent_color_option *new_option;
+struct percent_color_option *list_head;
+{
+	if (list_head == NULL)
+		return new_option;
+	if (new_option->percentage <= list_head->percentage) {
+		new_option->next = list_head;
+		return new_option;
+	}
+	list_head->next = add_percent_option(new_option, list_head->next);
+	return list_head;
+}
+
+boolean
+parse_status_color_option(start)
+char *start;
+{
+	char *middle;
+
+	while (*start && isspace(*start)) start++;
+	for (middle = start; *middle != ':' && *middle != '=' && *middle != '\0'; ++middle);
+	*middle++ = '\0';
+	if (middle - start > 2 && start[2] == '%') {
+		struct percent_color_option *percent_color_option =
+			(struct percent_color_option *)alloc(sizeof(*percent_color_option));
+		percent_color_option->next = NULL;
+		percent_color_option->percentage = atoi(start + 3);
+		percent_color_option->color_option = parse_color_option(middle);
+		start[2] = '\0';
+		if (percent_color_option->color_option.color >= 0
+		 && percent_color_option->color_option.attr_bits >= 0) {
+			if (!strcmpi(start, "hp")) {
+				hp_colors = add_percent_option(percent_color_option, hp_colors);
+				return TRUE;
+			}
+			if (!strcmpi(start, "pw")) {
+				pw_colors = add_percent_option(percent_color_option, pw_colors);
+				return TRUE;
+			}
+		}
+		free(percent_color_option);
+		return FALSE;
+	} else {
+		int length = strlen(start) + 1;
+		struct text_color_option *text_color_option =
+			(struct text_color_option *)alloc(sizeof(*text_color_option));
+		text_color_option->next = NULL;
+		text_color_option->text = (char *)alloc(length);
+		memcpy((char *)text_color_option->text, start, length);
+		text_color_option->color_option = parse_color_option(middle);
+		if (text_color_option->color_option.color >= 0
+		 && text_color_option->color_option.attr_bits >= 0) {
+			text_color_option->next = text_colors;
+			text_colors = text_color_option;
+			return TRUE;
+		}
+		free(text_color_option->text);
+		free(text_color_option);
+		return FALSE;
+	}
+}
+
+boolean
+parse_status_color_options(start)
+char *start;
+{
+	char last = ',';
+	char *end = start - 1;
+	boolean ok = TRUE;
+	while (last == ',') {
+		for (start = ++end; *end != ',' && *end != '\0'; ++end);
+		last = *end;
+		*end = '\0';
+		ok = parse_status_color_option(start) && ok;
+	}
+	return ok;
+}
+
+
+#endif /* STATUS_COLORS */
+
 void
 parseoptions(opts, tinitial, tfrom_file)
 register char *opts;
@@ -1839,6 +2004,17 @@ goodfruit:
 	    return;
 	}
 
+	fullname = "statuscolor";
+	if (match_optname(opts, fullname, 11, TRUE)) {
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+		if (negated) bad_negation(fullname, FALSE);
+		else if ((op = string_for_env_opt(fullname, opts, FALSE)) != 0)
+			if (!parse_status_color_options(op))
+				badoption(opts);
+#endif
+	    return;
+	}
+	
 	fullname = "suppress_alert";
 	if (match_optname(opts, fullname, 4, TRUE)) {
 		op = string_for_opt(opts, negated);
diff -Nurdp nethack-3.4.3/src/save.c nethack-3.4.3.statuscolors/src/save.c
--- nethack-3.4.3/src/save.c	2003-12-07 15:39:13.000000000 -0800
+++ nethack-3.4.3.statuscolors/src/save.c	2006-11-11 19:45:02.000000000 -0800
@@ -48,6 +48,12 @@ static long nulls[10];
 #define HUP
 #endif
 
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+extern const struct percent_color_option *hp_colors;
+extern const struct percent_color_option *pw_colors;
+extern const struct text_color_option *text_colors;
+#endif
+
 /* need to preserve these during save to avoid accessing freed memory */
 static unsigned ustuck_id = 0, usteed_id = 0;
 
@@ -942,6 +948,36 @@ register int fd, mode;
 	    ffruit = 0;
 }
 
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+
+void
+free_percent_color_options(list_head)
+const struct percent_color_option *list_head;
+{
+	if (list_head == NULL) return;
+	free_percent_color_options(list_head->next);
+	free(list_head);
+}
+
+void
+free_text_color_options(list_head)
+const struct text_color_option *list_head;
+{
+	if (list_head == NULL) return;
+	free_text_color_options(list_head->next);
+	free(list_head->text);
+	free(list_head);
+}
+
+void
+free_status_colors()
+{
+	free_percent_color_options(hp_colors); hp_colors = NULL;
+	free_percent_color_options(pw_colors); pw_colors = NULL;
+	free_text_color_options(text_colors); text_colors = NULL;
+}
+#endif
+
 /* also called by prscore(); this probably belongs in dungeon.c... */
 void
 free_dungeons()
@@ -956,6 +992,9 @@ free_dungeons()
 void
 freedynamicdata()
 {
+#if defined(STATUS_COLORS) && defined(TEXTCOLOR)
+	free_status_colors();
+#endif
 	unload_qtlist();
 	free_invbuf();	/* let_to_name (invent.c) */
 	free_youbuf();	/* You_buf,&c (pline.c) */


This patch improves the prompt when NetHack asks the player to specify
a location.

In vanilla NetHack you can let the cursor directly jump to stairs by
pressing '>' or '<', to fountains by '{', to altars by '_', etc.

But only if the location isn't covered by objects and for sinks and
grave this mechanism doesn't work as '|' and '#' also matches for
walls and corridors.

This is mainly an issue if your using the travel command '_' to quickly
navigate through the dungeon.

With this patch NetHack also finds dungeon features hidden by objects
and corridors and walls are never selected as target locations.

Bug reports can be directed to:
http://apps.sf.net/trac/unnethack/newticket

Patric Mueller <bhaak@gmx.net>

diff -uwr nethack-linux/src/do_name.c nethack-travel-improved/src/do_name.c
--- nethack-linux/src/do_name.c	2008-05-26 19:47:02.000000000 +0200
+++ nethack-travel-improved/src/do_name.c	2010-02-17 21:39:09.000000000 +0100
@@ -142,9 +142,28 @@
 			    lo_x = (pass == 0 && ty == lo_y) ? cx + 1 : 1;
 			    hi_x = (pass == 1 && ty == hi_y) ? cx : COLNO - 1;
 			    for (tx = lo_x; tx <= hi_x; tx++) {
-				k = levl[tx][ty].glyph;
+				/* look at dungeon feature, not at user-visible glyph */
+				k = back_to_glyph(tx,ty);
+				/* uninteresting background glyph */
 				if (glyph_is_cmap(k) &&
-					matching[glyph_to_cmap(k)]) {
+				    (IS_DOOR(levl[tx][ty].typ) || /* monsters mimicking a door */
+				     glyph_to_cmap(k) == S_room ||
+				     glyph_to_cmap(k) == S_corr ||
+				     glyph_to_cmap(k) == S_litcorr)) {
+					/* what the user remembers to be at tx,ty */
+					k = glyph_at(tx, ty);
+				}
+				/* TODO: - open doors are only matched with '-' */
+				/* should remembered or seen items be matched? */
+				if (glyph_is_cmap(k) &&
+					matching[glyph_to_cmap(k)] &&
+					levl[tx][ty].seenv && /* only if already seen */
+					(!IS_WALL(levl[tx][ty].typ) &&
+					 (levl[tx][ty].typ != SDOOR) &&
+					 glyph_to_cmap(k) != S_room &&
+					 glyph_to_cmap(k) != S_corr &&
+					 glyph_to_cmap(k) != S_litcorr)
+				    ) {
 				    cx = tx,  cy = ty;
 				    if (msg_given) {
 					clear_nhwindow(WIN_MESSAGE);



diff -urd nethack-3.4.3/dat/opthelp nh343par/dat/opthelp
--- nethack-3.4.3/dat/opthelp	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/dat/opthelp	2007-08-06 09:39:43.000000000 +0300
@@ -61,6 +61,15 @@
 Boolean option if MFLOPPY was set at compile time:
 checkspace check free disk space before writing files to disk     [TRUE]
 
+Boolean option if PARANOID was set at compile time:
+paranoid_hit   ask for explicit 'yes' when hitting peacefuls      [FALSE]
+
+Boolean option if PARANOID was set at compile time:
+paranoid_quit  ask for explicit 'yes' when quitting               [FALSE]
+
+Boolean option if PARANOID was set at compile time:
+paranoid_remove always show menu with the T and R commands        [FALSE]
+
 Boolean option if EXP_ON_BOTL was set at compile time:
 showexp    display your accumulated experience points             [FALSE]
 
diff -urd nethack-3.4.3/doc/Guidebook.mn nh343par/doc/Guidebook.mn
--- nethack-3.4.3/doc/Guidebook.mn	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/doc/Guidebook.mn	2007-08-06 09:39:43.000000000 +0300
@@ -2027,6 +2027,15 @@
 The value of this option should be a string containing the
 symbols for the various object types.  Any omitted types are filled in
 at the end from the previous order.
+.lp paranoid_hit
+If true, asks you to type the word ``yes'' when hitting any peaceful
+monster, not just the letter ``y''.
+.lp paranoid_quit
+If true, asks you to type the word ``yes'' when quitting or entering
+Explore mode, not just the letter ``y''.
+.lp paranoid_remove
+If true, always show menu with the R and T commands even when there is
+only one item to remove or take off.
 .lp perm_invent
 If true, always display your current inventory in a window.  This only
 makes sense for windowing system interfaces that implement this feature.
diff -urd nethack-3.4.3/doc/Guidebook.tex nh343par/doc/Guidebook.tex
--- nethack-3.4.3/doc/Guidebook.tex	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/doc/Guidebook.tex	2007-08-06 09:39:43.000000000 +0300
@@ -2486,6 +2486,18 @@
 containing the symbols for the various object types.  Any omitted types
 are filled in at the end from the previous order.
 %.lp
+\item[\ib{paranoid\_hit}]
+If true, asks you to type the word ``yes'' when hitting any peaceful
+monster, not just the letter ``y''.
+%.lp
+\item[\ib{paranoid\_quit}]
+If true, asks you to type the word ``yes'' when quitting or entering
+Explore mode, not just the letter ``y''.
+%.lp
+\item[\ib{paranoid\_remove}]
+If true, always show menu with the R and T commands even when there is
+only one item to remove or take off.
+%.lp
 \item[\ib{perm\_invent}]
 If true, always display your current inventory in a window.  This only
 makes sense for windowing system interfaces that implement this feature.
diff -urd nethack-3.4.3/doc/Guidebook.txt nh343par/doc/Guidebook.txt
--- nethack-3.4.3/doc/Guidebook.txt	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/doc/Guidebook.txt	2007-08-06 09:39:43.000000000 +0300
@@ -2607,6 +2607,18 @@
             Any  omitted  types  are filled in at the end from the previous
             order.
 
+          paranoid_hit
+            If true, asks you to type the word ``yes'' when hitting any
+            peaceful monster, not just the letter ``y''.
+
+          paranoid_quit
+            If true, asks you  to type the word ``yes'' when quitting or
+            entering Explore mode, not just the letter ``y''.
+
+          paranoid_remove
+            If true, always show menu with the R and T commands even when
+	    there is only one item to remove or take off.
+
           perm_invent
             If true, always display your current  inventory  in  a  window.
             This  only makes sense for windowing system interfaces that im-
diff -urd nethack-3.4.3/include/flag.h nh343par/include/flag.h
--- nethack-3.4.3/include/flag.h	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/include/flag.h	2007-08-06 09:39:43.000000000 +0300
@@ -216,6 +216,11 @@
 	boolean lan_mail;	/* mail is initialized */
 	boolean lan_mail_fetched; /* mail is awaiting display */
 #endif
+#ifdef PARANOID
+	boolean  paranoid_hit;  /* Ask for 'yes' when hitting peacefuls */
+	boolean  paranoid_quit; /* Ask for 'yes' when quitting */
+	boolean  paranoid_remove; /* Always show menu for 'T' and 'R' */
+#endif
 /*
  * Window capability support.
  */
diff -urd nethack-3.4.3/src/cmd.c nh343par/src/cmd.c
--- nethack-3.4.3/src/cmd.c	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/src/cmd.c	2007-08-06 09:39:43.000000000 +0300
@@ -478,9 +478,26 @@
 STATIC_PTR int
 enter_explore_mode()
 {
+#ifdef PARANOID
+	char buf[BUFSZ];
+	int really_xplor = FALSE;
+#endif
 	if(!discover && !wizard) {
 		pline("Beware!  From explore mode there will be no return to normal game.");
+#ifdef PARANOID
+		if (iflags.paranoid_quit) {
+		  getlin ("Do you want to enter explore mode? [yes/no]?",buf);
+		  (void) lcase (buf);
+		  if (!(strcmp (buf, "yes"))) really_xplor = TRUE;
+		} else {
+		  if (yn("Do you want to enter explore mode?") == 'y') {
+		    really_xplor = TRUE;
+		  }
+		}
+		if (really_xplor) {
+#else
 		if (yn("Do you want to enter explore mode?") == 'y') {
+#endif
 			clear_nhwindow(WIN_MESSAGE);
 			You("are now in non-scoring explore mode.");
 			discover = TRUE;
diff -urd nethack-3.4.3/src/do_wear.c nh343par/src/do_wear.c
--- nethack-3.4.3/src/do_wear.c	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/src/do_wear.c	2007-08-06 09:39:43.000000000 +0300
@@ -1078,7 +1078,11 @@
 			  "  Use 'R' command to remove accessories." : "");
 		return 0;
 	}
-	if (armorpieces > 1)
+	if (armorpieces > 1
+#ifdef PARANOID
+	    || iflags.paranoid_remove
+#endif
+	    )
 		otmp = getobj(clothes, "take off");
 	if (otmp == 0) return(0);
 	if (!(otmp->owornmask & W_ARMOR)) {
@@ -1128,7 +1132,11 @@
 		      "  Use 'T' command to take off armor." : "");
 		return(0);
 	}
-	if (Accessories != 1) otmp = getobj(accessories, "remove");
+	if (Accessories != 1
+#ifdef PARANOID
+	    || iflags.paranoid_remove
+#endif
+	    ) otmp = getobj(accessories, "remove");
 	if(!otmp) return(0);
 	if(!(otmp->owornmask & (W_RING | W_AMUL | W_TOOL))) {
 		You("are not wearing that.");
diff -urd nethack-3.4.3/src/end.c nh343par/src/end.c
--- nethack-3.4.3/src/end.c	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/src/end.c	2007-08-06 09:39:43.000000000 +0300
@@ -112,7 +112,21 @@
 int
 done2()
 {
+#ifdef PARANOID
+	char buf[BUFSZ];
+	int really_quit = FALSE;
+
+	if (iflags.paranoid_quit) {
+	  getlin ("Really quit [yes/no]?",buf);
+	  (void) lcase (buf);
+	  if (!(strcmp (buf, "yes"))) really_quit = TRUE;
+	} else {
+	  if(yn("Really quit?") == 'y') really_quit = TRUE;
+	}
+	if (!really_quit) {
+#else /* PARANOID */
 	if(yn("Really quit?") == 'n') {
+#endif /* PARANOID */
 #ifndef NO_SIGNAL
 		(void) signal(SIGINT, (SIG_RET_TYPE) done1);
 #endif
@@ -536,6 +550,10 @@
 done(how)
 int how;
 {
+#if defined(WIZARD) && defined(PARANOID)
+	char paranoid_buf[BUFSZ];
+	int really_bon = TRUE;
+#endif
 	boolean taken;
 	char kilbuf[BUFSZ], pbuf[BUFSZ];
 	winid endwin = WIN_ERR;
@@ -725,8 +743,18 @@
 
 	if (bones_ok) {
 #ifdef WIZARD
+# ifdef PARANOID
+	    if(wizard) {
+		getlin("Save WIZARD MODE bones? [no/yes]", paranoid_buf);
+		(void) lcase (paranoid_buf);
+		if (strcmp (paranoid_buf, "yes"))
+		  really_bon = FALSE;
+            }
+            if(really_bon)
+# else
 	    if (!wizard || yn("Save bones?") == 'y')
-#endif
+#endif /* PARANOID */
+#endif /* WIZARD */
 		savebones(corpse);
 	    /* corpse may be invalid pointer now so
 		ensure that it isn't used again */
diff -urd nethack-3.4.3/src/options.c nh343par/src/options.c
--- nethack-3.4.3/src/options.c	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/src/options.c	2007-08-06 09:39:43.000000000 +0300
@@ -143,6 +143,11 @@
 #else
 	{"page_wait", (boolean *)0, FALSE, SET_IN_FILE},
 #endif
+#ifdef PARANOID
+	{"paranoid_hit", &iflags.paranoid_hit, FALSE, SET_IN_GAME},
+	{"paranoid_quit", &iflags.paranoid_quit, FALSE, SET_IN_GAME},
+	{"paranoid_remove", &iflags.paranoid_remove, FALSE, SET_IN_GAME},
+#endif
 	{"perm_invent", &flags.perm_invent, FALSE, SET_IN_GAME},
 	{"popup_dialog",  &iflags.wc_popup_dialog, FALSE, SET_IN_GAME},	/*WC*/
 	{"prayconfirm", &flags.prayconfirm, TRUE, SET_IN_GAME},
diff -urd nethack-3.4.3/src/potion.c nh343par/src/potion.c
--- nethack-3.4.3/src/potion.c	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/src/potion.c	2007-08-06 09:39:51.000000000 +0300
@@ -1539,13 +1539,22 @@
 	here = levl[u.ux][u.uy].typ;
 	/* Is there a fountain to dip into here? */
 	if (IS_FOUNTAIN(here)) {
+#ifdef PARANOID
+		Sprintf(qbuf, "Dip %s into the fountain?", the(xname(obj)));
+		if(yn(qbuf) == 'y') {
+#else
 		if(yn("Dip it into the fountain?") == 'y') {
+#endif
 			dipfountain(obj);
 			return(1);
 		}
 	} else if (is_pool(u.ux,u.uy)) {
 		tmp = waterbody_name(u.ux,u.uy);
+#ifdef PARANOID
+		Sprintf(qbuf, "Dip %s into the %s?", the(xname(obj)), tmp);
+#else
 		Sprintf(qbuf, "Dip it into the %s?", tmp);
+#endif
 		if (yn(qbuf) == 'y') {
 		    if (Levitation) {
 			floating_above(tmp);
@@ -1562,7 +1571,12 @@
 		}
 	}
 
+#ifdef PARANOID
+	Sprintf(qbuf, "dip %s into", the(xname(obj)));
+	if(!(potion = getobj(beverages, qbuf)))
+#else
 	if(!(potion = getobj(beverages, "dip into")))
+#endif
 		return(0);
 	if (potion == obj && potion->quan == 1L) {
 		pline("That is a potion bottle, not a Klein bottle!");
Only in nh343par/src: potion.c.orig
diff -urd nethack-3.4.3/src/uhitm.c nh343par/src/uhitm.c
--- nethack-3.4.3/src/uhitm.c	2003-12-08 01:39:13.000000000 +0200
+++ nh343par/src/uhitm.c	2007-08-06 09:39:43.000000000 +0300
@@ -99,6 +99,9 @@
 struct obj *wep;	/* uwep for attack(), null for kick_monster() */
 {
 	char qbuf[QBUFSZ];
+#ifdef PARANOID
+	char buf[BUFSZ];
+#endif
 
 	/* if you're close enough to attack, alert any waiting monster */
 	mtmp->mstrategy &= ~STRAT_WAITMASK;
@@ -199,11 +202,26 @@
 			return(FALSE);
 		}
 		if (canspotmon(mtmp)) {
+#ifdef PARANOID
+			Sprintf(qbuf, "Really attack %s? [no/yes]",
+				mon_nam(mtmp));
+			if (iflags.paranoid_hit) {
+				getlin (qbuf, buf);
+				(void) lcase (buf);
+				if (strcmp (buf, "yes")) {
+				  flags.move = 0;
+				  return(TRUE);
+				}
+			} else {
+#endif
 			Sprintf(qbuf, "Really attack %s?", mon_nam(mtmp));
 			if (yn(qbuf) != 'y') {
 				flags.move = 0;
 				return(TRUE);
 			}
+#ifdef PARANOID
+			}
+#endif
 		}
 	}
 
