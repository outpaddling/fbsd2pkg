
# TODO:
#   Process PKGNAMEPREFIX and PKGNAMESUFFIX

BEGIN {
    printf("# $NetBSD$\n\n");
    
    printf("###########################################################\n");
    printf("#               Generated by fbsd2pkg                     #\n");
    printf("###########################################################\n\n");

    printf("###########################################################\n");
    printf("# Unconverted and partially converted FreeBSD port syntax:\n\n");
}

{
    if ( $1 ~ "^PORTNAME" )
	portname = $2;
    else if ( $1 ~ "^PORTVERSION" )
	portversion = $2;
    else if ( $1 ~ "^DISTNAME" )
    {
	distname = $2;
	sub("\\${PORTNAME}", portname, distname);
    }
    else if ( $1 ~ "^DISTFILES" )
    {
	distfiles = $2;
	sub("\\${PORTNAME}", portname, distfiles);
    }
    else if ( $1 ~ "^EXTRACT_SUFX" )
	extract_sufx = $2;
    else if ( $1 ~ "^CATEGORIES" )
	category = $2;
    else if ( $1 ~ "^MASTER_SITES" )
    {
	master_sites = $2;
	if ( master_sites ~ "github" )
	    use_curl = 1;
	else if ( master_sites ~ "^SF" )
	{
	    fbsd_master_sites = master_sites;
	    master_sites = "${MASTER_SITE_SOURCEFORGE:=" portname "/}";
	}
	sub("\\${PORTNAME}", portname, master_sites);
    }
    else if ( $1 ~ "^MAINTAINER" )
    {
	# Ignore this and use maintainer from the command line
    }
    else if ( $1 ~ "^COMMENT" )
	comment = $0;
    else if ( $1 ~ "^LICENSE" )
    {
	license = $2;
	known_license = 0;
	if ( license ~ "^LGPL" )
	{
	    sub("GPL", "gnu-lgpl-", license);
	    known_license = 1;
	}
	else if ( license ~ "^GPL" )
	{
	    sub("GPL", "gnu-gpl-", license);
	    known_license = 1;
	}
    }
    else if ( $1 ~ "^GNU_CONFIGURE" )
	gnu_configure = 1;
    else if ( $1 ~ "^CONFIGURE_ENV" )
	configure_env = $0;
    else if ( $1 ~ "^CONFIGURE_ARGS" )
	configure_args = $0;
    else if ( $1 ~ "^CFLAGS" )
	cflags = $0;
    else if ( $1 ~ "^USES" )
    {
	for (f = 2; f <= NF; ++f)
	{
	    if ( $f == "tar:bzip2" )
		extract_sufx=".tar.bz2";
	    if ( $f == "tar:tgz" )
		extract_sufx=".tgz";
	    if ( $f == "tar:xz" )
		extract_sufx=".tar.xz";
	    if ( $f == "tar:txz" )
		extract_sufx=".txz";
	    else if ( $f == "zip" )
		extract_sufx=".zip";
	    else if ( $f == "perl5" )
	    {
		# Ignore this and just convert USE_PERL
	    }
	    else if ( $f == "pkgconfig" )
		use_tools = use_tools "pkg-config";
	    else if ( $f == "gmake" )
		use_tools = use_tools "gmake";
	    else if ( $f == "libtool" )
		use_libtool = "yes";
	    else if ( $f == "shebangfix" )
	    {
		shebang_fix = 1;
	    }
	    else
		printf("# Unknown tool: USE_TOOLS=\t%s\n", $f);
	}
    }
    else if ( $1 ~ "^ONLY_FOR_ARCHS" )
    {
	for (f = 2; f <= NF; ++f)
	{
	    if ( $f == "amd64" )
		only_for_platform = only_for_platform " *-*-x86_64";
	    else
		only_for_platform = only_for_platform " *-*-" $f;
	}
    }
    else if ( $1 ~ "_DEPENDS" )
    {
	has_depends = 1;
	printf("#%s\n", $0);
    }
    else if ( $1 ~ "^WRKSRC" )
    {
	wrksrc = $0;
	sub("\\${PORTNAME}", portname, wrksrc);
    }
    else if ( $1 ~ "^NO_BUILD" )
	no_build = 1;
    else if ( $1 ~ "^ALL_TARGET" )
    {
	$1 = "";
	#do_build = "cd ${WRKSRC} && ${MAKE_PROGRAM} " $0;
	build_target = $0;
    }
    else if ( $1 ~ "^USE_PYTHON" )
	use_python_run=1;
    else if ( $1 ~ "^USE_PERL" )
	use_tools = use_tools " perl:" $2;
    else if ( $1 ~ "^PKGNAMEPREFIX" )
	pkgnameprefix=$0;
    else if ( $1 ~ "^PKGNAMESUFFIX" )
	pkgnamesuffix=$0;
    else if ( $0 != "" )
    {
	# Convert what we can in FreeBSD ports code that's left commented out
	sub("STAGEDIR", "DESTDIR", $0);
	
	if ( ($0 ~ "COPYTREE") && (use_tools !~ "pax") )
	    use_tools = use_tools " pax";
	sub("\\${COPYTREE_.+}", "pax -rw", $0);
	
	printf("#%s\n", $0);
	if ( $0 ~ "REINPLACE_CMD" )
	    use_subst = 1;
    }
}

END {
    if ( distname != "" )
    {
	printf("\nPKGNAME=\t%s-${PORTVERSION}\n", portname);
	printf("DISTNAME=\t%s\n", distname);
    }
    else
	printf("\nDISTNAME=\t%s-${PORTVERSION}\n", portname);
    if ( distfiles != "" )
	printf("DISTFILES=\t%s\n", distfiles);
    printf("CATEGORIES=\t%s\n", category);
    if ( fbsd_master_sites != "" )
	printf("# FreeBSD MASTER_SITES: %s\n", fbsd_master_sites);
    printf("MASTER_SITES=\t%s\n", master_sites);
    if ( extract_sufx != "" )
	printf("EXTRACT_SUFX=\t%s\n", extract_sufx);
    
    printf("\nMAINTAINER=\t%s\n", maintainer);
    
    printf("\n%s\n", comment);
    
    if ( known_license )
	printf("LICENSE=\t%s\n", license);
    else
	printf("#LICENSE=\t%s\n", license);

    printf("\n# Pessimistic assumption.  Test and change if possible.\n");
    printf("MAKE_JOBS_SAFE=\tno\n");
    
    printf("\nONLY_FOR_PLATFORM=\t%s\n", only_for_platform);
    
    printf("\n# Just assuming C and C++: Adjust this!\nUSE_LANGUAGES=\tc c++\n");
    if ( use_tools != "" )
	printf("USE_TOOLS+=\t%s\n", use_tools);
    if ( use_libtool == "yes" )
	printf("USE_LIBTOOL=\tyes\n");
    if ( gnu_configure )
	printf("GNU_CONFIGURE=\tyes\n");
    if ( shebang_fix )
    {
	printf("# FreeBSD's SHEBANG_FILES may include bash, perl, python, etc.\n");
	printf("# I don't know which is which, so you'll have to finish.\n");
	printf("# Add bash, etc. to USE_TOOLS if used below.\n");
	printf("#%s\n", shebang_files);
	printf("REPLACE_SH=\t\n");
	printf("REPLACE_BASH=\t\n");
	printf("REPLACE_CSH=\t\n");
	printf("REPLACE_KSH=\t\n");
	printf("REPLACE_PERL=\t\n");
	printf("REPLACE_PYTHON=\t\n");
    }
    if ( no_build == 1 )
	printf("NO_BUILD=\tyes\n");
	
    if ( wrksrc != "" )
	printf("\n%s\n", wrksrc);
    
    if ( use_subst )
    {
	printf("\n# Adapt REINPLACE commands to SUBST:\n");
	printf("SUBST_CLASSES+=\t\t\n");
	printf("SUBST_STAGE.=\t\n");
	printf("SUBST_MESSAGE.=\t\n");
	printf("SUBST_FILES.=\t\n");
	printf("SUBST_SED.=\t-e 's|||g'\n");
    }

    if ( configure_env != "" )
    {
	printf("\n");
	printf("%s\n", configure_env);
    }
    if ( configure_args != "" )
    {
	printf("\n");
	printf("%s\n", configure_args);
    }
    if ( cflags != "" )
    {
	printf("\n");
	printf("%s\n", cflags);
    }
    
    if ( build_target != "" )
	printf("BUILD_TARGET=\t%s\n", build_target);

    if ( use_curl )
	printf("\nFETCH_USING=\tcurl\n");

    printf("\nPORTVERSION=\t%s\n", portversion);
    printf("DATADIR=\t${PREFIX}/share/%s\n", portname);
    printf("DOCSDIR=\t${PREFIX}/share/doc/%s\n", portname);
    if ( pkgnameprefix != "" )
	printf("%s\n", pkgnameprefix);
    if ( pkgnamesuffix != "" )
	printf("%s\n", pkgnamesuffix);
    
    printf("\n# Sets OPSYS, OS_VERSION, MACHINE_ARCH, etc..\n");
    printf("#.include \"../../mk/bsd.prefs.mk\"\n");
    
    printf("\n# Keep this if there are user-selectable options.\n");
    printf("#.include \"options.mk\"\n");
    
    printf("\n# You may need this, especially if using do-install.\n");
    printf("\n# Note: Depends on PLIST.\n");
    printf("#AUTO_MKDIRS=\tyes\n");
    
    printf("\n");
    if ( use_python_run )
    {
	printf("# Guess based on FreeBSD USE_PYTHON_RUN=yes\n");
	printf(".include \"../../lang/python/application.mk\"\n");
    }
    if ( has_depends )
    {
	printf("# Add any _DEPENDS that have a buildlink3.mk\n");
	printf("#.include \"../..///buildlink3.mk\"\n");
    }
    printf(".include \"../../mk/bsd.pkg.mk\"\n");
}

