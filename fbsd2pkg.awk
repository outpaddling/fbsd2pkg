
function check_continuation()
{
    # Remove trailing '\' whether separate or nestled
    if ( $NF == "\\" )
    {
	--NF;
	more_lines = 1;
    }
    else if ( substr($0, length($0), 1) == "\\" )
    {
	$0 = substr($0, 1, length()-1);
	more_lines = 1;
    }
    else
	more_lines = 0;
}


function get_and_print_line()
{
    getline;
    printf("# %s\n", $0);
    check_continuation();
    field = 1;
}


function check_i_eol()
{
    if ( (i > length()) && more_lines )
    {
	get_and_print_line();
	i = 1;
    }
}


function skip_whitespace()
{
    do
    {
	arg_str = arg_str ch;
	++i;
	check_i_eol();
	ch = substr($0, i, 1);
    }   while ( (ch == " ") || (ch == "\t" ) );
}


function get_continued_line()
{
    check_continuation();
    while ( more_lines )
    {
	getline;
	continued_line = continued_line " \\\n\t\t" $1;
	check_continuation();
    }
    gsub("LOCALBASE", "PREFIX", continued_line);
}

# TODO:
#   Process PKGNAMEPREFIX and PKGNAMESUFFIX

BEGIN {
    printf("# $NetBSD$\n#\n");
    printf("###########################################################\n");
    printf("#                  Generated by fbsd2pkg                  #\n");
    "date" | getline today
    printf("#          %32s               #\n", today);
    printf("###########################################################\n\n");

    printf("###########################################################\n");
    printf("# Unconverted and partially converted FreeBSD port syntax:\n\n");
    subst_file=1;
    use_languages="c c++";
}

{
    gsub("LOCALBASE", "PREFIX");
    gsub("MAKE_CMD", "MAKE_PROGRAM");
    if ( $1 ~ "^PORTNAME" )
    {
	# Start here and override if distname, pkgname prefix, etc. specified
	portname = $2;
	pkgname = portname;
	distname = portname;
    }
    else if ( $1 ~ "^PORTVERSION" )
	portversion = $2;
    else if ( $1 ~ "^DISTNAME" )
    {
	explicit_distname = $2;
	distname = explicit_distname;
	gsub("\\${PORTNAME}", portname, explicit_distname);
    }
    else if ( $1 ~ "^DIST_SUBDIR" )
    {
	dist_subdir = $2;
	gsub("\\${PORTNAME}", portname, dist_subdir);
    }
    else if ( $1 ~ "^DISTVERSIONSUFFIX" )
    {
	distversionsuffix = $2;
    }
    else if ( $1 ~ "^DISTVERSIONPREFIX" )
    {
	distversionprefix = $2;
    }
    else if ( $1 ~ "^DISTFILES" )
    {
	distfiles = $2;
	gsub("\\${PORTNAME}", portname, distfiles);
    }
    else if ( $1 ~ "^EXTRACT_SUFX" )
	extract_sufx = $2;
    else if ( $1 ~ "^CATEGORIES" )
	categories = $2;
    # Check this before MASTER_SITES!
    else if ( $1 ~ "^MASTER_SITE_SUBDIR" )
	master_site_subdir = $2;
    else if ( $1 ~ "^MASTER_SITES" )
    {
	master_sites = $2;
	if ( master_sites ~ "^SF" )
	    sf_master_sites = master_sites;
	else if ( master_sites == "CHEESESHOP" )
	    master_sites = "${MASTER_SITE_PYPI:=" substr(portname,1,1) "/" portname "/}";
	else if ( master_sites == "CPAN" )
	{
	    split(portname, a, "-");
	    perl_mod = 1;
	    no_installation_dirs = 1;
	    master_sites = "${MASTER_SITE_PERL_CPAN:=" a[1] "/}";
	}
	else
	    gsub("\\${PORTNAME}", portname, master_sites);
	
	get_continued_line()
	master_sites = master_sites continued_line;
    }
    else if ( $1 ~ "^MAINTAINER" )
    {
	# Ignore this and use maintainer from the command line
    }
    else if ( $1 ~ "^COMMENT" )
	comment = $0;
    else if ( $1 ~ "^LICENSE=" )
    {
	license = $2;
	known_license = 0;
	if ( license ~ "^LGPL" )
	{
	    gsub("LGPL", "gnu-lgpl-", license);
	    known_license = 1;
	}
	else if ( license ~ "^GPL" )
	{
	    gsub("GPL", "gnu-gpl-", license);
	    known_license = 1;
	}
	else if ( license == "BSD3CLAUSE" )
	{
	    license = "modified-bsd";
	    known_license = 1;
	}
	else if ( license == "BSD2CLAUSE" )
	{
	    license = "2-clause-bsd";
	    known_license = 1;
	}
	else if ( license == "MIT" )
	{
	    license = "mit";
	    known_license = 1;
	}
	else if ( license == "ART10" )
	{
	    license = "artistic";
	    known_license = 1;
	}
	else if ( license == "ART20" )
	{
	    license = "artistic-2.0";
	    known_license = 1;
	}
	else if ( license == "APACHE20" )
	{
	    license = "apache-2.0";
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
    else if ( $1 ~ "^CXXFLAGS" )
	cxxflags = $0;
    else if ( $1 ~ "^FFLAGS" )
	fflags = $0;
    else if ( $1 ~ "^LDFLAGS" )
	ldlags = $0;
    else if ( $1 ~ "^MAKEFILE" )
	make_file = $2;
    else if ( $1 ~ "^MAKE_ARGS" )
    {
	make_flags = $0;
	gsub("MAKE_ARGS", "MAKE_FLAGS", make_flags);
    }
    else if ( $1 ~ "^MAKE_ENV" )
	make_env = $2;
    else if ( $1 ~ "^CMAKE_ARGS" )
    {
	cmake_args = $2;
	get_continued_line();
	cmake_args = cmake_args continued_line;
    }
    else if ( ($1 ~ "^CMAKE_VERBOSE") && ($2 == "yes") )
	make_flags = make_flags "VERBOSE=1"
    else if ( $1 ~ "^USES" )
    {
	for (f = 2; f <= NF; ++f)
	{
	    if ( $f == "tar:bzip2" )
		extract_sufx=".tar.bz2";
	    else if ( $f == "tar:tgz" )
		extract_sufx=".tgz";
	    else if ( $f == "tar:xz" )
		extract_sufx=".tar.xz";
	    else if ( $f == "tar:txz" )
		extract_sufx=".txz";
	    else if ( $f == "zip" )
		extract_sufx=".zip";
	    else if ( $f == "perl5" )
		use_perl=1
	    else if ( $f == "python" )
		use_python=1
	    else if ( $f == "bison" )
		use_tools = use_tools " bison";
	    else if ( $f == "fortran" )
		use_languages = use_languages " fortran";
	    else if ( $f == "gmake" )
		use_tools = use_tools " gmake";
	    else if ( $f == "libtool" )
		use_libtool = "yes";
	    else if ( $f == "pkgconfig" )
		use_tools = use_tools " pkg-config";
	    else if ( $f == "ssl" )
		use_ssl=1
	    else if ( $f == "shebangfix" )
		shebang_fix = 1;
	    else if ( $f == "dos2unix" )
		dos2unix = 1;
	    else if ( $f == "ncurses" )
		buildlink = buildlink "devel/ncurses";
	    else if ( $f == "autoreconf" )
	    {
		use_tools = use_tools "autoconf automake autoreconf";
		auto_tools = " && autoreconf -if";
	    }
	    else if ( $f == "compiler:openmp" )
	    {
		if ( cflags == "" )
		    cflags="CFLAGS=\t\t";
		cflags = cflags "-fopenmp ";
		if ( cxxflags == "" )
		    cxxflags="CXXFLAGS=\t";
		cxxflags = cxxflags "-fopenmp ";
		if ( fflags == "" )
		    fflags="FFLAGS=\t\t";
		fflags = fflags "-fopenmp ";
	    }
	    else if ( $f ~ "cmake" )
	    {
		printf("# Note: %s\n", $f);
		use_cmake = 1;
	    }
	    else if ( $f == "metaport" )
	    {
		meta_package=1
		categories="meta-pkgs"
		master_sites="# empty"
		distfiles="# empty"
	    }
	    else
		printf("# Unknown tool: USE_TOOLS=\t%s\n", $f);
	}
    }
    else if ( $1 ~ "^DOS2UNIX_FILES" )
    {
	check_continuation();
	d2f_count = 0;
	for (c = 2; c <= NF; ++c)
	{
	    ++d2f_count;
	    dos2unix_files[d2f_count] = $c;
	}
	# FIXME: Replace with get_continued_line()?
	while ( more_lines )
	{
	    getline;
	    check_continuation();
	    for (c = 1; c <= NF; ++c)
	    {
		++d2f_count;
		dos2unix_files[d2f_count] = $c;
	    }
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
	printf("# %s\n", $0);
    }
    else if ( $1 ~ "^WRKSRC" )
    {
	wrksrc = $0;
	gsub("\\${PORTNAME}", portname, wrksrc);
	gsub("\\${GH_TAGNAME}", "${GITHUB_TAG}", wrksrc);
	gsub("\\${GH_PROJECT}", "${GITHUB_PROJECT}", wrksrc);
    }
    else if ( $1 ~ "^NO_BUILD" )
	no_build = 1;
    else if ( $1 ~ "^ALL_TARGET" )
    {
	$1 = "";
	build_target = $0;
    }
    else if ( $1 ~ "^INSTALL_TARGET" )
    {
	gsub("STAGEDIR", "DESTDIR", $0);
	install_target = $0;
    }
    else if ( $1 ~ "^USE_GITHUB" )
    {
	use_github = 1;
	use_curl = 1;
    }
    else if ( $1 ~ "^GH_ACCOUNT") 
	gh_account = $2;
    else if ( $1 ~ "^GH_PROJECT")
	gh_project = $2;
    else if ( $1 ~ "^GH_TAGNAME")
	gh_tagname = $2;
    # Deprecated in favor of USES=, but leave it in for now
    else if ( $1 ~ "^USE_AUTOTOOLS" )
    {
	for (f = 2; f <= NF; ++f)
	{
	    use_tools = use_tools " " $f;
	    auto_tools = auto_tools " && " $f;
	    # printf("%s\n", $f);
	}
	# printf("auto_tools = %s\n", auto_tools);
    }
    else if ( $1 ~ "^USE_PYTHON" )
    {
	n = split($0, uses, "[ \t]");
	for (c = 2; c <= n; ++c)
	{
	    if ( uses[c] == "run" )
		use_python_run=1;
	    else if ( uses[c] == "distutils" )
		use_python_distutils=1;
	}
    }
    else if ( $1 ~ "^USE_PERL" )
    {
	gsub("configure", "pkgsrc", $2);
	use_tools = use_tools " perl:" $2;
    }
    else if ( $1 ~ "^PKGNAMEPREFIX" )
    {
	pkgnameprefix=$2;
	gsub("\\${PYTHON_PKGNAMEPREFIX}", "${PYPKGPREFIX}-", pkgnameprefix);
    }
    else if ( $1 ~ "^PKGNAMESUFFIX" )
	pkgnamesuffix=$2;
    else if ( $0 != "" )
    {
	if ( $1 ~ "REINPLACE_CMD" )
	{
	    printf("\n# Best guess translation of REINPLACE above.  Replace %s with a\n", subst_file) > subst_file;
	    printf("# meaningful name.  Assuming post-patch: Change if necessary.\n") >> subst_file;
	    printf("#SUBST_CLASSES+=\t\t%s\n", subst_file) >> subst_file;
	    printf("#SUBST_STAGE.%s=\tpost-patch\n", subst_file) >> subst_file;
	    first_field = 2;
	    more_lines = 1;
	    while ( more_lines )
	    {
		printf("# %s\n", $0);
		check_continuation();
		for (field = first_field; field <= NF; ++field)
		{
		    if ( ($field == "-e") || ($field == "-E") || ($field == "-i") )
		    {
			# Print flag
			printf("#SUBST_SED.%s+=\t%s ", subst_file, $field) >> subst_file;
			++field;
			
			if ( field > NF )
			    get_and_print_line();
			
			# Print string after flag.  If it's a quoted
			# string, it may contain spaces, so we have to
			# process character by character rather than just
			# use the next field.
			first_ch = substr($field, 1, 1);
			arg_str = first_ch;
			if ( ( first_ch == "'" ) || ( first_ch == "\"" ) )
			{
			    # Position of 2nd character in $field within line
			    i = index($0, $field) + 1;
			    do
			    {
				# Strings may span lines
				check_i_eol();
				
				ch = substr($0, i, 1);
				
				# Handle escaped chars.  Trailing '\' has
				# already been removed at this point, so
				# there is something after this one.
				if ( ch == "\\" )
				{
				    ++i;
				    ch = substr($0, i, 1);
				}
				else if ( (ch == " ") || (ch == "\t" ) )
				{
				    ++field;
				    skip_whitespace();
				    ch = substr($0, i, 1);
				}
				
				arg_str = arg_str ch;
				++i;
			    }   while ( ch != first_ch );
			    printf("%s\n", arg_str) >> subst_file;
			}
			else
			    printf("%s\n", $field) >> subst_file;
		    }
		    else
			printf("#SUBST_FILES.%s+=\t%s\n", subst_file, $field) >> subst_file;
		}
		if ( more_lines )
		{
		    getline;
		    first_field = 1;
		}
	    }
	    system("cat " subst_file " && rm -f " subst_file);
	    printf("\n");
	    ++subst_file;
	}
	else
	{
	    # Convert what we can in FreeBSD ports code that's left commented out
	    gsub("STAGEDIR", "DESTDIR", $0);
	    gsub("STRIP_CMD", "STRIP", $0);
	    gsub("post-stage", "post-install", $0);
	    gsub("\\${PYTHON_PKGNAMEPREFIX}", "${PYPKGPREFIX}-", $0);
	    gsub("\\${PORTSDIR}", "../..", $0);
	    
	    if ( ($0 ~ "COPYTREE") && (use_tools !~ "pax") )
		use_tools = use_tools " pax";
	    # Unfortunately, pkgsrc pax does not support -c to exclude .orig
	    # files
	    gsub("\\${COPYTREE_[A-Z]+}", "pax -rw", $0);
	    printf("#%s\n", $0);
	}
    }
}

END {
    if ( pkgnameprefix != "" )
    {
	pkgname = pkgnameprefix pkgname
    }
    if ( pkgnamesuffix != "" )
    {
	pkgname = pkgname pkgnamesuffix
    }
    if ( explicit_distname != "" )
    {
	printf("\nDISTNAME=\t%s\n", explicit_distname);
	printf("PKGNAME=\t%s-${PORTVERSION}\n", pkgname);
    }
    else if ( ( distname != pkgname ) || (distversionsuffix != "") )
    {
	printf("\nDISTNAME=\t%s-${PORTVERSION}%s\n", distname, distversionsuffix);
	printf("PKGNAME=\t%s-${PORTVERSION}\n", pkgname);
    }
    else
	printf("\nDISTNAME=\t%s-${PORTVERSION}\n", distname);
    if ( dist_subdir != "" )
    {
	printf("\nPKGNAME=\t%s-${PORTVERSION}\n", pkgname);
	printf("DIST_SUBDIR=\t%s\n", dist_subdir);
    }
    printf("CATEGORIES=\t%s\n", categories);

    if ( sf_master_sites != "" )
    {
	if ( master_site_subdir != "" )
	    master_sites = "${MASTER_SITE_SOURCEFORGE:=" master_site_subdir "}";
	else
	    master_sites = "${MASTER_SITE_SOURCEFORGE:=" portname "/}";
	printf("# FreeBSD MASTER_SITES: %s\n", sf_master_sites);
    }
    else if ( master_site_subdir != "" )
	printf("# FreeBSD MASTER_SITE_SUBDIR: %s\n", master_site_subdir);
    
    if ( use_github )
    {
	master_sites="${MASTER_SITE_GITHUB:=";
	if ( gh_account != "" )
	    master_sites = master_sites gh_account "/";
	else
	    master_sites = master_sites pkgname "/";
	master_sites = master_sites "}";
    }
    
    printf("MASTER_SITES=\t%s\n", master_sites);
    if ( distfiles != "" )
	printf("DISTFILES=\t%s\n", distfiles);

    if ( use_github )
    {
	if ( gh_project == "" )
	    gh_project=portname;
	printf("GITHUB_PROJECT=\t%s\n", gh_project);
	if ( gh_tagname == "" )
	    gh_tagname="${PORTVERSION}";
	if ( distversionprefix != "" )
	    gh_tagname = distversionprefix gh_tagname;
	printf("GITHUB_TAG=\t%s\n", gh_tagname);
    }
    
    if ( extract_sufx != "" )
	printf("EXTRACT_SUFX=\t%s\n", extract_sufx);
    
    printf("\nMAINTAINER=\t%s\n", maintainer);
    printf("HOMEPAGE=\t%s\n", homepage);
    printf("%s\n", comment);
    
    if ( meta_package )
	printf("\nMETA_PACKAGE=\tyes\n");
    
    if ( dos2unix )
	printf("\nDEPENDS+=\tdos2unix:../../converters/dos2unix\n\n");
    
    if ( ! meta_package )
    {
	if ( known_license )
	    printf("# Check this\nLICENSE=\t%s\n", license);
	else
	    printf("# LICENSE=\t%s\n", license);

	printf("\n# Test and change if necessary.\n");
	printf("# MAKE_JOBS_SAFE=\tno\n");
    }
    
    if ( only_for_platform != "" )
	printf("\nONLY_FOR_PLATFORM=\t%s\n", only_for_platform);
    
    printf("\n# Just assuming C and C++: Adjust this!\nUSE_LANGUAGES=\t%s\n", use_languages);
    if ( use_tools != "" )
    {
	gsub("^ ", "", use_tools);   # Remove leading space from first add       
	printf("USE_TOOLS+=\t%s\n", use_tools);
    }
    if ( use_python_distutils == 1 )
	printf("PYDISTUTILSPKG=\tyes\n");
    if ( use_libtool == "yes" )
	printf("USE_LIBTOOL=\tyes\n");
    if ( gnu_configure )
	printf("GNU_CONFIGURE=\tyes\n");
    if ( shebang_fix )
    {
	printf("# FreeBSD's SHEBANG_FILES may include bash, perl, python, etc.\n");
	printf("# I don't know which is which, so you'll have to finish.\n");
	printf("# Add bash, etc. to USE_TOOLS if used below.\n");
	printf("# %s\n", shebang_files);
	printf("REPLACE_SH=\t\n");
	printf("REPLACE_BASH=\t\n");
	printf("REPLACE_CSH=\t\n");
	printf("REPLACE_KSH=\t\n");
	printf("REPLACE_PERL=\t\n");
	printf("REPLACE_PYTHON=\t\n");
    }
    if ( use_cmake )
	printf("USE_CMAKE=\tyes\n");
    if ( cmake_args != "" )
	printf("# Check this\nCMAKE_ARGS+=\t%s\n", cmake_args);

    if ( no_build == 1 )
	printf("NO_BUILD=\tyes\n");
	
    if ( wrksrc != "" )
	printf("\n%s\n", wrksrc);
    
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
    if ( cxxflags != "" )
    {
	printf("\n");
	printf("%s\n", cxxflags);
    }
    if ( fflags != "" )
    {
	printf("\n");
	printf("%s\n", fflags);
    }
    if ( ldflags != "" )
    {
	printf("\n");
	printf("%s\n", ldflags);
    }

    if ( make_file != "" )
	printf("MAKE_FILE=\t%s\n", make_file);
    
    if ( make_flags != "" )
	printf("# Check this\n%s\n", make_flags);
    
    if ( make_env != "" )
	printf("# Check this\nMAKE_ENV+=\t%s\n", make_env);

    if ( build_target != "" )
	printf("BUILD_TARGET=\t%s\n", build_target);

    if ( install_target != "" )
	printf("%s\n", install_target);
    
    printf("\nPORTVERSION=\t%s\n", portversion);
    if ( use_perl )
	printf("SITE_PERL=\t${PREFIX}/share\n");
    printf("DATADIR=\t${PREFIX}/share/%s\n", portname);
    printf("DOCSDIR=\t${PREFIX}/share/doc/%s\n", portname);
    printf("EXAMPLESDIR=\t${PREFIX}/share/examples/%s\n", portname);
    if ( master_sites ~ "CHEESESHOP" )
    {
	# Extract stem for cheeseshop subdir
	distname_stem = distname;
	if ( (pos=index(distname_stem, "-")) != 0 )
	    distname_stem = substr(distname_stem, 1, pos-1);

	printf("CHEESESHOP=\thttp://pypi.python.org/packages/source/%c/%s/\n",
		substr(distname_stem,1,1),distname_stem);
    }
    
    printf("\n# Sets OPSYS, OS_VERSION, MACHINE_ARCH, etc..\n");
    printf("# .include \"../../mk/bsd.prefs.mk\"\n");
    
    printf("\n# Keep this if there are user-selectable options.\n");
    printf("# .include \"options.mk\"\n");
    
    if ( ! no_installation_dirs )
    {
	printf("\n# Specify which directories to create before install.\n");
	printf("# You should only need this if using your own install target.\n");
	printf("INSTALLATION_DIRS=\tbin include lib ${PKGMANDIR}/man1 share/doc share/examples\n");
    }
    
    if ( dos2unix )
    {
	printf("\npre-patch:\n\tdos2unix \\\n");
	for (c = 1; c < d2f_count; ++c)
	    printf("\t\t${WRKSRC}/%s \\\n", dos2unix_files[c]);
	printf("\t\t${WRKSRC}/%s\n", dos2unix_files[c]);
    }
    
    if ( auto_tools != "" )
	printf("\npre-configure:\n\tcd ${WRKSRC}%s\n", auto_tools);
    
    printf("\n");
    if ( use_python_run )
    {
	printf("# Guess based on FreeBSD USE_PYTHON_RUN=yes\n");
	printf(".include \"../../lang/python/application.mk\"\n");
    }
    if ( use_python_distutils )
    {
	printf("# Verify that we shouldn't use egg.mk or extensions.mk instead.\n");
	printf(".include \"../../lang/python/distutils.mk\"\n");
    }
    if ( perl_mod )
    {
	printf("# Based on CPAN MASTER_SITES.\n");
	printf(".include \"../../lang/perl5/module.mk\"\n");
    }
    if ( buildlink != "" )
    {
	gsub("^ ", "", buildlink);   # Remove leading space from first add
	n = split(buildlink, pkgs, " ");
	for ( c in pkgs )
	{
	    printf("# Guess based on USES=\n.include \"../../%s/buildlink3.mk\"\n", pkgs[c]);
	}
    }
    if ( has_depends )
    {
	printf("# Convert any _DEPENDS above that have a buildlink3.mk\n");
	printf("# .include \"../..///buildlink3.mk\"\n");
    }
    if ( use_python )
    {
	printf("# Based on USES=python.  Check this.\n");
	printf(".include \"../../lang/python/application.mk\"\n");
    }
    if ( use_ssl )
    {
	printf(".include \"../../security/openssl/buildlink3.mk\"\n");
    }
    
    printf("# Linux doesn't have zlib in the base, so just in case...\n");
    printf("# .include \"../../devel/zlib/buildlink3.mk\"\n");
    printf(".include \"../../mk/bsd.pkg.mk\"\n");
}

