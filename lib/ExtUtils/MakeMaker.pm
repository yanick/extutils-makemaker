package ExtUtils::MakeMaker;

# Version 3.1    Last edited 11th Nov 1994 by Tim Bunce

use Config;
use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&WriteMakefile &mkbootstrap $Verbose &writeMakefile);
@EXPORT_OK = qw(%att %skip %recognized_att_keys @mm_sections &runsubdirpl);

use strict qw(refs);
$Verbose = 0;
$^W=1;


=head1 NAME

ExtUtils::MakeMaker - create an extension Makefile

=head1 SYNOPSIS

use ExtUtils::MakeMaker;
&writeMakefile("LIBS" => ["-L/usr/alpha -lfoo -lbar"]);

=head1 DESCRIPTION

This utility is designed to write a Makefile for an extension 
module from a Makefile.PL. It is based on the excellent Makefile.SH
model provided by Andy Dougherty and the perl5-porters. 

It splits the task of generating the Makefile into several
subroutines that can be individually overridden.
Each subroutine returns the text it wishes to have written to
the Makefile.

The following attributes can be specified as arguments to &writeMakefile
or as NAME=VALUE pairs on the command line:

=head2 Customizing The Generated Makefile

If the Makefile generated does not fit your purpose you can
change it using the mechanisms described below.

=head3 Using Attributes (and Parameters)

... not yet written ...

=head3 Overriding MakeMaker Methods

You may specify private subroutines in the Makefile.PL.
Each subroutines returns the text it wishes to have written to
the Makefile. To override a section of the Makefile you can
either say:

	sub MY::c_o { "new literal text" }

or you can edit the default by saying something like:

	sub MY::c_o { $_=MM->c_o; s/old text/new text/; $_ }

If you still need a different solution, try to develop another 
subroutine, that fits your needs and submit the diffs to 
perl5-porters@isu.edu or comp.lang.perl as appropriate.


=head1 AUTHORS

Andy Dougherty <doughera@lafcol.lafayette.edu>
Andreas Koenig <k@franz.ww.TU-Berlin.DE>
Tim Bunce <Tim.Bunce@ig.co.uk>

=head1 MODIFICATION HISTORY

v1, August 1994; by Andreas Koenig.

Excellent initial version. Based on Andy Dougherty's Makefile.SH work.

v2, September 1994; by Tim Bunce.

Use inheritance to implement overriding.  Methods return text so
derived methods can edit it before it's output.  mkbootstrap() now
executes the *_BS file in the DynaLoader package and automatically adds
dl_findfile() if required. More support for nested modules.

v3.0, October/November 1994; by Tim Bunce.

Major reorganisation. Fixed perl binary locating code. Replaced single
$(TOP) with $(PERL_SRC), $(PERL_LIB) and $(INST_LIB).  Restructured
code.  Consolidated and/or eliminated several attributes and added
argument name checking. Added initial pod documentation. Made generated
Makefile easier to read. Added generic mechanism for passing parameters
to specific sections of the Makefile. Merged in Andreas' perl version
of Andy's extliblist.

v3.1 November 11th 1994 by Tim Bunce

Fixed AIX dynamic loading problem for nested modules. Fixed perl
extliblist to give paths not names for libs so that cross-check works.
Converted the .xs to .c translation to a suffix rule. Added a .xs.o
rule for dumb makes.  Added very useful PM, XS and DIR attributes. Used
new attributes to make other sections smarter (especially clean and
realclean). Make clean no longer deletes Makefile so that a later make
realclean can still work. Fixed all known problems.

MakeMaker development work still to be done:

Better Documentation

Replace use of cflags with %Config (taking note of hints etc)

Reduce use of $(PERL_SRC) (will require installperl changes etc):

 - extliblist (already on it's way out)
 - cflags (replace via %Config, assumes flags for all files are identical)
 - ext.libs (convert usage to: cat `?/ext_libs/*` ?)
 - xsubpp  (move into lib/ExtUtils/...)
 - typemap (move into lib/ExtUtils/...)
 - perldepend section

=cut


# Setup dummy package:
# MY exists for overriding methods to be defined within
unshift(@MY::ISA, qw(MM));


$attrib_help = <<'END';
 NAME:		Perl module name for this extension (DBD::Oracle)
		This defaults to the directory name.

 DISTNAME:	Your name for distributing the package (by tar file)
		This defaults to NAME above.

 VERSION:	Your version number for distributing the package.
		This defaults to 0.1.

 INST_LIB:	Perl library directory to install the module into.
 PERL_LIB:	Directory containing the Perl library to use.
 PERL_SRC:	Directory containing the Perl source code
		(use of this should be avoided, it may be removed later)

 INC:		Include file dirs eg: '-I/usr/5include -I/path/to/inc'
 DEFINE:	something like "-DHAVE_UNISTD_H"
 OBJECT:	List of object files, defaults to '$(BASEEXT).o',
		but can be a long string containing all object files,
		    e.g. "tkpBind.o tkpButton.o tkpCanvas.o"
 MYEXTLIB:	If the extension links to a library that it builds
		set this to the name of the library (see SDBM_File)

 LIBS:		An anonymous array of libraries to be searched for
		until we get at least some output from ext/util/extliblist
		    'LIBS' => [ "-lgdbm", "-ldbm -lfoo", "-ldbm.nfs" ]

 LDTARGET:	defaults to "$(OBJECT)" and is used in the ld command
		(some machines need additional switches for bigger projects)

 ARMAYBE:	Defaults to ":", but can be used to run ar before ld

 PM:		Hashref of .pm files. MakeMaker will default this.
		e.g. { 'name_of_file.pm' => '$(INST_LIB)/install_as.pm'}

 XS:		Hashref of .xs files. MakeMaker will default this.
		e.g. { 'name_of_file.xs' => 'name_of_file.c' }

 DIR:		Ref to array of subdirectories containing Makefile.PL's
		e.g. [ 'sdbm' ] in ext/SDBM_File

 LINKTYPE:	=>'static' or 'dynamic' (default unless usedl=undef in config.sh)
 CONFIG:	=>[qw(archname manext)] defines ARCHNAME & MANEXT from config.sh
 SKIP:  	=>[qw(name1 name2)] skip (don't write) sections of the Makefile


 PERL:
 FULLPERL:

Additional lowercase attributes can be used to pass parameters to the
methods which implement that part of the Makefile:

 clean:		{FILES => "*.xyz foo"}
 realclean:	{FILES => "$(AUTOEXT)/*.xyz"}
 distclean:	{TARNAME=>'MyTarName', TARFLAGS=>'cvfF', COMPRESS=>'gzip'}
 tool_autosplit:	{MAXLEN => 8}
END

@mm_sections = qw(
    post_initialize
    constants const_loadlibs const_config
    const_cccmd const_tools
    tool_autosplit tool_xsubpp
    post_constants
    top_targets
    dynamic dynamic_lib dynamic_bs
    static static_lib
    c_o xs_c xs_o
    installpm subdirs
    clean realclean distclean test install
    force perldepend postamble
);

%recognized_att_keys = ();
foreach(split(/\n/,$attrib_help)){
    chomp;
    next unless m/^\s*(\w+):\s*(.*)/;
    $recognized_att_keys{$1} = $2;
    print "Attribute '$1' => '$2'\n" if ($Verbose >= 2);
}
@recognized_att_keys{@mm_sections} = @mm_sections;

%att  = ();
%skip = ();


sub writeMakefile {
    carp "Change &writeMakefile to &writeMakefile\n";
    &WriteMakefile;
}

sub WriteMakefile {
    %att = @_;
    local($\)="\n";

    print STDOUT "MakeMaker" if $Verbose;

    parse_args(\%att, @ARGV);
    my(%initial_att) = %att; # record initial attributes

    MY->initialize(@ARGV);

    print STDOUT "Writing Makefile for $att{NAME}";

    unlink("Makefile", "Makefile.new");
    open MAKE, ">Makefile.new" or die "Unable to open Makefile: $!";
    select MAKE; $|=1; select STDOUT;

    print MAKE "# This Makefile is for the $att{NAME} extension to perl.\n#";
    print MAKE "# It was written by Makefile.PL, so don't edit it, edit";
    print MAKE "# Makefile.PL instead. ANY CHANGES MADE HERE WILL BE LOST!\n#";
    print MAKE "#	MakeMaker Parameters: ";
    foreach $key (sort keys %initial_att){
	my($v) = neatvalue($initial_att{$key});
	$v =~ tr/\n/ /s;
	print MAKE "#		$key => $v";
    }

    # build hash for SKIP to make testing easy
    %skip = map( ($_,1), @{$att{'SKIP'} || []});

    foreach $section ( @mm_sections ){
	print "Creating Makefile '$section' section" if ($Verbose >= 2);
	if ($skip{$section}){
	    print MAKE "\n# --- MakeMaker $section section skipped.";
	} else {
	    my(%a) = %{$att{$section} || {}};
	    print MAKE "\n# --- MakeMaker $section section:";
	    print MAKE "# ",%a if ($Verbose >= 2);
	    print(MAKE MY->$section( %a ));
	}
    }

    print MAKE "\n# End.";
    close MAKE;
    rename("Makefile.new", "Makefile");

    chmod 0644, "Makefile";
    system("$Config{'eunicefix'} Makefile") unless $Config{'eunicefix'} eq ":";

    1;
}


sub mkbootstrap{
    parse_args(\%att, @ARGV);
    MY->mkbootstrap(@_)
}


# Experimental!
sub runsubdirpl{
    my($subdir) = @_;
    chdir($subdir) or die "chdir($subdir): $!";
    open(MKPL, "<Makefile.PL") or die "open $subdir/Makefile.PL: $!";
    eval join('', <MKPL>);
    die "$subdir/Makefile.PL failed: $@\n" if $@;
}


sub parse_args{
    my($attr, @args) = @_;
    foreach (@args){
	next unless m/(.*)=(.*)/;
	$$attr{$1} = $2;
    }
    # catch old-style and inform user how to 'upgrade'
    if (defined $$attr{'potential_libs'}){
	my($msg)="'potential_libs' => '$$attr{potential_libs}' should be";
	if ($$attr{'potential_libs'}){
	    print STDERR "$msg changed to 'LIBS' => ['$$attr{potential_libs}']\n";
	} else {
	    print STDERR "$msg deleted.\n";
	}
	$$attr{LIBS} = [$$attr{'potential_libs'}];
	delete $$attr{'potential_libs'};
    }
    foreach(sort keys %{$attr}){
	print STDOUT "	$_ => ".neatvalue($$attr{$_}) if ($Verbose);
	warn "'$_' is not a known MakeMaker parameter name.\n"
	    unless exists $recognized_att_keys{$_};
    }
}


sub neatvalue{
    my($v) = @_;
    my($t) = ref $v;
    return "'$v'" unless $t;
    return "[ ".join(', ',map("'$_'",@$v))." ]" if $t eq 'ARRAY';
    return "$v" unless $t eq 'HASH';
    my(@m, $key, $val);
    push(@m,"$key=>".neatvalue($val)) while (($key,$val) = each %$v);
    return "{ ".join(', ',@m)." }";
}


# --- Define the MakeMaker default methods ---

package MM;

use Config;
require Exporter;

Exporter::import('ExtUtils::MakeMaker',
	qw(%att %skip %recognized_att_keys $Verbose));

# These attributes cannot be overridden externally
@other_att_keys{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS MYEXTLIB)} = (1) x 3;



sub initialize {
    # Find out directory name.  This may also be the extension name.
    chop($pwd=`pwd`);

    # --- Initialize PERL_LIB, INST_LIB, PERL_SRC

    unless ($att{PERL_SRC}){
	foreach(qw(../.. ../../.. ../../../..)){
	    ($att{PERL_SRC}=$_, last) if -f "$_/config.sh";
	}
    }
    die "Unable to locate perl source. Try setting PERL_SRC\n"
	unless ($att{PERL_SRC});

    $att{CONFIG_SH} = "$att{PERL_SRC}/config.sh";
    $att{INST_LIB}  = "$att{PERL_SRC}/lib" unless ($att{INST_LIB});
    $att{PERL_LIB}  = $att{INST_LIB} unless $att{PERL_LIB};

    # make a few simple checks
    die "Can't find config.sh" unless (-f $att{CONFIG_SH});
    die "INST_LIB ($att{INST_LIB}) is not a perl library directory"
	unless (-f "$att{INST_LIB}/Exporter.pm");

    # --- Initialize Module Name and Paths

    # NAME    = The perl module name for this extension (eg DBD::Oracle).
    # FULLEXT = Pathname for extension directory (eg DBD/Oracle).
    # BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
    # ROOTEXT = Directory part of FULLEXT. May be empty.
    unless($att{NAME}){ # we have to guess our name
	my($name) = $pwd;
	$name =~ s:.*/:: unless ($name =~ s:^.*/ext/::);
	($att{NAME} =$name) =~ s#/#::#g;
    }
    ($att{FULLEXT} =$att{NAME}) =~ s#::#/#g ;		#eg. BSD/Foo/Socket
    ($att{BASEEXT} =$att{NAME}) =~ s#.*::##;		#eg. Socket
    ($att{ROOTEXT} =$att{NAME}) =~ s#(::)?\Q$att{BASEEXT}\E$## ; # eg. BSD/Foo

    ($att{DISTNAME}=$att{NAME}) =~ s#(::)#-#g;
    $att{VERSION} = "0.1" unless $att{VERSION};


    # --- Initialize Perl Binary Locations

    # Find Perl 5. The only contract here is that both 'PERL' and 'FULLPERL'
    # will be working versions of perl 5.
    $att{'PERL'} = MY->find_perl(5.0, [ qw(perl5 perl miniperl) ],
			    [ $att{PERL_SRC}, split(":", $ENV{PATH}) ], 0 )
	    unless ($att{'PERL'} && -x $att{'PERL'});

    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($att{'FULLPERL'} = $att{'PERL'}) =~ s/miniperl/perl/
	unless ($att{'FULLPERL'} && -x $att{'FULLPERL'});


    # --- Initialize File and Directory Lists (.xs and .pm)

    {
	my($name, @dirs, %xs, %pm);
	opendir(DIR, ".") || die $!;
	foreach $name (readdir(DIR)){
	    next if $name =~ /^\./;
	    if (-f "$name/Makefile.PL"){
		push(@dirs, $name);
	    }elsif ($name =~ /\.xs$/){
		my($c); ($c = $name) =~ s/\.xs$/.c/;
		$xs{$name} = $c;
	    }elsif ($name =~ /\.pm$/){
		$pm{$name} = "\$(INST_LIB)/$att{FULLEXT}.pm";
	    }
	}
	closedir(DIR);

	$att{DIRS} = [@dirs] unless $att{DIRS};
	$att{XS}   = {%xs}   unless $att{XS};
	$att{PM}   = {%pm}   unless $att{PM};
    }

    # --- Initialize Other Attributes

    for $key (keys(%recognized_att_keys), keys(%other_att_keys)){
	# avoid warnings for uninitialized vars
	next if exists $att{$key};
	$att{$key} = "";
    }

    # compute EXTRALIBS, BSLOADLIBS and LDLOADLIBS from $att{'LIBS'}
    foreach ( @{$att{'LIBS'} || []} ){
	my(@libs) = MY->extliblist($_);
	if ($libs[0] or $libs[1] or $libs[2]){
	    @att{EXTRALIBS, BSLOADLIBS, LDLOADLIBS} = @libs;
	    last;
	}
    }

    warn "CONFIG must be an array ref\n"
	if ($att{CONFIG} and ref $att{CONFIG} ne 'ARRAY');
    $att{CONFIG} = [] unless (ref $att{CONFIG});
    push(@{$att{CONFIG}},
	qw( cc libc ldflags lddlflags ccdlflags cccdlflags
	    ranlib so dlext dlsrc installprivlib installarchlib
	));
    push(@{$att{CONFIG}}, 'shellflags') if $Config{'shellflags'};

    $att{BOOTDEP}  = (-f "$att{BASEEXT}_BS") ? "$att{BASEEXT}_BS" : "";
    $att{OBJECT}   = '$(BASEEXT).o' unless $att{OBJECT};
    $att{LDTARGET} = '$(OBJECT)'    unless $att{LDTARGET};
    $att{LINKTYPE} = ($Config{'usedl'}) ? 'dynamic' : 'static'
	unless $att{LINKTYPE};

}


sub find_perl{
    my($self, $ver, $names, $dirs, $trace) = @_;
    my($name, $dir);
    print "Looking for perl $ver by these names: @$names, in these dirs: @$dirs\n"
	if ($trace);
    foreach $dir (@$dirs){
	foreach $name (@$names){
	    print "checking $dir/$name\n" if ($trace >= 2);
	    next unless -x "$dir/$name";
	    print "executing $dir/$name\n" if ($trace);
	    my($out) = `$dir/$name -e 'require $ver; print "VER_OK\n" ' 2>&1`;
	    return "$dir/$name" if $out =~ /VER_OK/;
	}
    }
    warn "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}


sub post_initialize{
    "";
}
 

sub constants {
    my(@m);

    push @m, "
NAME = $att{NAME}
DISTNAME = $att{DISTNAME}
VERSION = $att{VERSION}

# Where should we install this extension
INST_LIB = $att{INST_LIB}

# Where is the perl source code located (eventually we should
# be able to build extensions without requiring the perl source
# but that's a long way off yet).
PERL_SRC = $att{PERL_SRC}
# Perl header files (will eventually be under INST_LIB or similar)
PERL_INC = $att{PERL_SRC}
# Perl library (typically same as INST_LIB)
PERL_LIB = $att{PERL_LIB}
# Perl binaries
PERL = $att{'PERL'}
FULLPERL = $att{'FULLPERL'}

TOP = TOP_deprecated_use_INST_LIB_or_PERL_SRC_instead

# FULLEXT = Pathname for extension directory (eg DBD/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT. May be empty.
FULLEXT = $att{FULLEXT}
BASEEXT = $att{BASEEXT}
ROOTEXT = $att{ROOTEXT}

INC = $att{INC}
DEFINE = $att{DEFINE}
OBJECT = $att{OBJECT}
LDTARGET = $att{LDTARGET}
LINKTYPE = $att{LINKTYPE}

.SUFFIXES: .xs

# This extension may link to it's own library
MYEXTLIB = $att{MYEXTLIB}

";

    push @m, '
# Where to put things:
AUTOEXT = $(INST_LIB)/auto/$(FULLEXT)
INST_BOOT = $(AUTOEXT)/$(BASEEXT).bs
INST_DYNAMIC = $(AUTOEXT)/$(BASEEXT).$(DLEXT)
INST_STATIC = $(BASEEXT).a
';

    join('',@m);
}


sub const_cccmd{
    # CCCMD/cflags: This is a temporary solution.
    # Eventually cflags will be replaced by MakeMaker using %Config directly.
    # We will need to deal with hints.
    chop($cccmd = `cd $att{PERL_SRC}; sh $Config{'shellflags'} ./cflags $att{BASEEXT}.c`);
    "CCCMD = $cccmd\n";
}


sub const_tools{
    q{
SHELL = /bin/sh

# The following is a portable way to say mkdir -p
MKPATH = $(PERL) -we '$$"="/"; foreach(split(/\//,$$ARGV[0])){ push(@p, $$_); next if -d "@p" or "@p" eq ""; print "mkdir @p\n"; mkdir("@p",0777)||die "mkdir @p: $$!" } exit 0;'
};
}


sub tool_autosplit{
    my($self, %attribs) = @_;
    my($asl) = $attribs{MAXLEN} || 8;
    q{
AUTOSPLITLIB = $(PERL) -I$(PERL_LIB) -e 'use AutoSplit; chdir("$(INST_LIB)/..") or die $$!; $$AutoSplit::Maxlen=}.$asl.q{; autosplit_lib_modules(@ARGV) ;'
};
}


sub tool_xsubpp{
    my(@tmdeps) = ('$(PERL_SRC)/ext/typemap');
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    "
XSUBPP = \$(PERL_SRC)/ext/xsubpp
XSUBPPDEPS = @tmdeps
XSUBPPARGS = @tmargs
";
};


sub const_config{
    my(@m);
    push(@m,"\n# These definitions are taken from config.sh (via Config.pm)\n");
    my(%once_only);
    foreach(@{$att{'CONFIG'}}){
	next if $once_only{$_};
	warn "CONFIG key '$_' does not exist in Config.pm\n"
		unless exists $Config{$_};
	push @m, "\U$_\E = $Config{$_}\n";
	$once_only{$_} = 1;
    }
    join('', @m);
}


sub const_loadlibs{
    "
# $att{NAME} might depend on some other libraries.
#
# Dependant libraries are linked in either by the ld command
# at build time or by the DynaLoader at bootstrap time.
# Which method is used depends in the platform and the types
# of libraries available (shared or non-shared).
#
# These comments may need revising:
#
# EXTRALIBS =	Full list of libraries needed for static linking.
#		Only those libraries that actually exist are included.
#
# BSLOADLIBS =	List of those libraries that are needed but can be
#		linked in dynamically on this platform.  On SunOS, for
#		example, this would be .so* libraries, but not archive
#		libraries.  The bootstrap file is installed only if
#		this list is not empty.
#
# LDLOADLIBS =	List of those libraries which must be statically
#		linked into the shared library.  On SunOS 4.1.3, 
#		for example,  I have only an archive version of -lm,
#		and it must be linked in statically.
#
EXTRALIBS  = $att{'EXTRALIBS'}
BSLOADLIBS = $att{'BSLOADLIBS'}
LDLOADLIBS = $att{'LDLOADLIBS'}
";
}


sub top_targets{
    '
all ::	$(LINKTYPE)

config :: Makefile
	@$(MKPATH) $(AUTOEXT)

install :: all
';
}


sub post_constants{
    "";
}


# --- Dynamic Loading Sections ---

sub dynamic {
    "
dynamic :: \$(INST_DYNAMIC) \$(INST_BOOT) ".join(" ",values %{$att{PM}})."
";
}

sub dynamic_lib {
    my($self, %attribs) = @_;
    my($otherldflags) = $attribs{OTHERLDLFLAGS} || "";
    $att{ARMAYBE} = ":" unless $att{ARMAYBE};
    '
ARMAYBE = '.$att{ARMAYBE}.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB)
	@$(MKPATH) $(AUTOEXT)
	$(ARMAYBE) cr $(BASEEXT).a $(OBJECT) 
	ld $(LDDLFLAGS) -o $@ $(LDTARGET) '.$otherldflags.' $(MYEXTLIB) $(LDLOADLIBS)
';
}

sub dynamic_bs {
    my($self, %attribs) = @_;
    '
BOOTSTRAP = '."$att{BASEEXT}.bs".'

$(BOOTSTRAP): '.$att{BOOTDEP}.'
	$(PERL) -I$(PERL_LIB) -e \'use ExtUtils::MakeMaker; &mkbootstrap("$(BSLOADLIBS)");\' INST_LIB=$(INST_LIB) PERL_SRC=$(PERL_SRC)
	@touch $(BOOTSTRAP)

$(INST_BOOT): $(BOOTSTRAP)
	@rm -f $(INST_BOOT)
	@test -s $(BOOTSTRAP) && cp $(BOOTSTRAP) $(INST_BOOT)
';
}


# --- Static Loading Sections ---

sub static {
    "
static :: \$(INST_STATIC) ".join(" ",values %{$att{PM}})."
";
}

sub static_lib{
    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB)
END
    # If this extension has it's own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) to it.
    push(@m, '	cp $(MYEXTLIB) $@'."\n") if $att{MYEXTLIB};

    push(@m, <<'END');
	ar cr $@ $(OBJECT)
	$(RANLIB) $@
	echo $(EXTRALIBS) >> $(PERL_SRC)/ext.libs
END
    join('', "\n",@m);
}


sub installpm {
    my($self, %attribs) = @_;
    my(@m);
    push(@m, '
INST_PM = $(INST_LIB)/$(FULLEXT).pm

$(INST_PM):	$(BASEEXT).pm
	@$(MKPATH) $(INST_LIB)/$(ROOTEXT)
	rm -f $@
	cp $(BASEEXT).pm $@
	$(AUTOSPLITLIB) $(NAME)
') if %{$att{PM}}; # will become a loop later
    join('', @m);
}


# --- Translation Sections ---

sub c_o {
    '
.c.o:
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}

sub xs_c {
    '
.xs.c:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >tmp && mv tmp $@
';
}

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    '
.xs.o:
	$(PERL) $(XSUBPP) $(XSUBPPARGS) $*.xs >tmp && mv tmp $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $(INC) $*.c
';
}


# --- Sub-directory Sections ---

sub subdirs {
    my(@m);
    # This method provides a mechanism to automatically deal with
    # subdirectories containing further Makefile.PL scripts.
    # It calls the subdir_x() method for each subdirectory.
    foreach(<*/Makefile.PL>){
	s:/Makefile\.PL$:: ;
	print "Including $_ subdirectory" if ($Verbose);
	push @m, MY->subdir_x($_);
    }
    join('',@m);
}

sub subdir_x {
    my($self, $subdir) = @_;
    my(@m);
    # The intention is that the calling Makefile.PL should define the
    # $(SUBDIR_MAKEFILE_PL_ARGS) make macro to contain whatever
    # information needs to be passed down to the other Makefile.PL scripts.
    # If this does not suit your needs you'll need to write your own
    # MY::subdir_x() method to override this one.
    qq{
config :: $subdir/Makefile
	cd $subdir ; \$(MAKE) config

$subdir/Makefile: $subdir/Makefile.PL \$(PERL_LIB)/Config.pm
}.'	@echo "Rebuilding $@ ..."
	$(PERL) -I$(PERL_LIB) \\
		-e "use ExtUtils::MakeMaker qw(&runsubdirpl); runsubdirpl(qw('.$subdir.'))" \\
		$(SUBDIR_MAKEFILE_PL_ARGS)
	@echo "Rebuild of $@ complete."
'.qq{

all ::
	cd $subdir ; \$(MAKE) all
};
}


# --- Cleanup and Distribution Sections ---

sub clean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m, '
# Delete temporary files but do not touch installed files
# We don\'t delete the Makefile here so that a
# later make realclean still has a makefile to work from
clean ::
	rm -f *.o *.a mon.out core so_locations $(BOOTSTRAP) $(BASEEXT).bso
');
    foreach(@{$att{DIRS}}){
	push(@m, "	cd $_ && test -f Makefile && \$(MAKE) clean\n");
    }
    # Automatically delete the .c files generated from *.xs files
    push(@m, "	rm -rf ".join(" ", values %{$att{XS}})."\n") if %{$att{XS}};
    push(@m, "	rm -rf $attribs{FILES}\n") if $attribs{FILES};
    push(@m, "	$attribs{POSTOP}\n")       if $attribs{POSTOP};
    join("", @m);
}

sub realclean {
    my($self, %attribs) = @_;
    my(@m);
    push(@m,'
# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	rm -f Makefile
	rm -f $(INST_DYNAMIC) $(INST_STATIC) $(INST_BOOT)
	rm -rf $(AUTOEXT)
');
    foreach(@{$att{DIRS}}){
	push(@m, "	cd $_ && test -f Makefile && \$(MAKE) realclean\n");
    }
    push(@m, "	rm -f ".join(" ", values %{$att{PM}})."\n") if %{$att{PM}};
    push(@m, "	rm -rf $attribs{FILES}\n") if $attribs{FILES};
    push(@m, "	$attribs{POSTOP}\n")       if $attribs{POSTOP};
    join("", @m);
}


sub distclean {
    my($self, %attribs) = @_;
    my($tarname)  = $attribs{TARNAME}  || '$(DISTNAME)-$(VERSION)';
    my($tarflags) = $attribs{TARFLAGS} || 'cvf';
    my($compress) = $attribs{COMPRESS} || 'compress';
    my($postop)     = $attribs{POSTOP} || "";
    "
distclean:     clean
	rm -f Makefile *~ t/*~
	cd ..; tar $tarflags $tarname.tar \$(BASEEXT)
	cd ..; $compress $tarname.tar
	$postop
";
}


# --- Test and Installation Sections ---

sub test {
    my($self, %attribs) = @_;
    my($tests) = $attribs{TESTS} || "t/*.t";
    "
test: all
	\$(FULLPERL) -I\$(PERL_LIB) -e 'use Test::Harness; runtests \@ARGV;' $tests
";
}


sub install {
    '
install :: all
	# Not defined. Makefile, by default, builds the extension directly
	# into $(INST_LIB) so "installing" does not make much sense.
	# If INST_LIB is in the perl source tree then installperl will
	# install the extension when it installs perl.
';
}


sub force {
    '
# Phony target to force checking subdirectories.
FORCE:
';
}


sub perldepend {
    '
$(OBJECT) : Makefile
$(OBJECT) : $(PERL_INC)/EXTERN.h
$(OBJECT) : $(PERL_INC)/INTERN.h
$(OBJECT) : $(PERL_INC)/XSUB.h
$(OBJECT) : $(PERL_INC)/av.h
$(OBJECT) : $(PERL_INC)/cop.h
$(OBJECT) : $(PERL_INC)/cv.h
$(OBJECT) : $(PERL_INC)/dosish.h
$(OBJECT) : $(PERL_INC)/embed.h
$(OBJECT) : $(PERL_INC)/form.h
$(OBJECT) : $(PERL_INC)/gv.h
$(OBJECT) : $(PERL_INC)/handy.h
$(OBJECT) : $(PERL_INC)/hv.h
$(OBJECT) : $(PERL_INC)/keywords.h
$(OBJECT) : $(PERL_INC)/mg.h
$(OBJECT) : $(PERL_INC)/op.h
$(OBJECT) : $(PERL_INC)/opcode.h
$(OBJECT) : $(PERL_INC)/patchlevel.h
$(OBJECT) : $(PERL_INC)/perl.h
$(OBJECT) : $(PERL_INC)/perly.h
$(OBJECT) : $(PERL_INC)/pp.h
$(OBJECT) : $(PERL_INC)/proto.h
$(OBJECT) : $(PERL_INC)/regcomp.h
$(OBJECT) : $(PERL_INC)/regexp.h
$(OBJECT) : $(PERL_INC)/scope.h
$(OBJECT) : $(PERL_INC)/sv.h
$(OBJECT) : $(PERL_INC)/unixish.h
$(OBJECT) : $(PERL_INC)/util.h
$(PERL_SRC)/config.h: $(PERL_SRC)/config.sh; cd $(PERL_SRC); /bin/sh config_h.SH
$(PERL_SRC)/embed.h:  $(PERL_SRC)/config.sh; cd $(PERL_SRC); /bin/sh embed_h.SH

Makefile:	Makefile.PL $(PERL_LIB)/Config.pm
	$(PERL) -I$(PERL_LIB) Makefile.PL
';
}


sub postamble{
    "";
}


# --- Determine libraries to use and how to use them ---

sub extliblist{
    my($self, $libs) = @_;
    return ("", "", "") unless $libs;
    print STDERR "Potential libraries are '$libs':" if $Verbose;
    my(@old) = MY->old_extliblist($libs);
    my(@new) = MY->new_extliblist($libs);

    my($oldlibs) = join(" : ",@old);
    my($newlibs) = join(" : ",@new);
    warn "Warning: $att{NAME} extliblist consistency check failed:\n".
	"  old: $oldlibs\n".
	"  new: $newlibs\n".
	"Using 'old' set. Please notify perl5-porters\@isu.edu.\n"
	    if "$newlibs" ne "$oldlibs";
    @old;
}


sub old_extliblist {
    my($self, $potential_libs)=@_;
    return ("", "", "") unless $potential_libs;

    my(%attrib, @w);
    # Now run ext/util/extliblist to discover what *libs definitions
    # are required for the needs of $potential_libs
    $ENV{'potential_libs'} = $potential_libs;
    my(@o)=`. $att{CONFIG_SH}
	    . $att{PERL_SRC}/ext/util/extliblist;
	    echo EXTRALIBS=\$extralibs
	    echo BSLOADLIBS=\$dynaloadlibs
	    echo LDLOADLIBS=\$statloadlibs
	    `;
    foreach $line (@o){
	chomp $line;
	if ($line =~ /(.*)\s*=\s*(.*)\s*$/){
	    $attrib{$1} = $2;
	    print STDERR "	$1 = $2" if $Verbose;
	}else{
	    push(@w, $line);
	}
    }
    print STDERR "Messages from extliblist:\n", join("\n",@w,'')
       if @w ;
    @attrib{qw(EXTRALIBS BSLOADLIBS LDLOADLIBS)};
}


sub new_extliblist {
    my($self, $potential_libs)=@_;
    return ("", "", "") unless $potential_libs;

    $so   = $Config{'so'};
    $libs = $Config{'libs'};

    # compute $extralibs, $bsloadlibs and $ldloadlibs from
    # $potential_libs
    # this is a rewrite of Andy Dougherty's extliblist in perl
    # its home is in <distribution>/ext/util

    my(@LIBPATH) = split " ", $Config{'libpth'};
    my(@ldloadlibs);
    my(@bsloadlibs);
    my(@extralibs);

    foreach $thislib (split ' ', $potential_libs){

	# Handle possible linker path arguments.
	if ($thislib =~ s/^-L//){
	    unless (-d $thislib){
		warn "-L$thislib ignored, directory does not exist\n"
			if $Verbose;
		next;
	    }
	    push(@LIBPATH, $thislib);
	    push(@extralibs,  "-L$thislib");
	    push(@ldloadlibs, "-L$thislib");
	    next;
	}

	# Handle possible library arguments.
	$thislib =~ s/^-l//;
	foreach $thispth (@LIBPATH){

	    if (@fullname=<${thispth}/lib${thislib}.${so}.[0-9]*>){
		$fullname=$fullname[-1]; #ATTN: 10 looses against 9!
	    } elsif (-f ($fullname="$thispth/lib$thislib.$so")){
	    } elsif (-f ($fullname="$thispth/lib${thislib}_s.a")){
	    } elsif (-f ($fullname="$thispth/lib$thislib.a")){
	    } elsif (-f ($fullname="$thispth/Slib$thislib.a")){
	    } else { 
		warn "$thislib not found in $thispth\n" if $Verbose;
		next;
	    }
	    warn "'-l$thislib' found at $fullname\n" if $Verbose;

	    # Now update library lists

	    # what do we know about this library...
	    my $is_dyna = ($fullname !~ /\.a$/);
	    my $in_perl = ($libs =~ /\B-l${thislib}\b|\B-l${thislib}_s\b/);

	    # Do not add it into the list if it is already linked in
	    # with the main perl executable.
	    push(@extralibs, "-l$thislib") unless $in_perl;

	    # We might be able to load this archive file dynamically
	    if ( $Config{'dlsrc'} =~ /dl_next|dl_dld/){
		# We push -l$thislib instead of $fullname because
		# it avoids hardwiring a fixed path into the .bs file.
		# mkbootstrap will automatically add dl_findfile() to
		# the .bs file if it sees a name in the -l format.
		# USE THIS LATER: push(@bsloadlibs, "-l$thislib"); # " $fullname";
		# USE THIS while checking results against old_extliblist
		push(@bsloadlibs, "$fullname");
	    } else {
		if ($is_dyna){
                    # For SunOS4, do not add in this shared library if
                    # it is already linked in the main perl executable
		    push(@ldloadlibs, "-l$thislib")
			unless ($in_perl and $Config{'osname'} eq 'sunos');
		} else {
		    push(@ldloadlibs, "-l$thislib");
		}
	    }
	    last;	# found one here so don't bother looking further
	}
    }
    ("@extralibs", "@bsloadlibs", "@ldloadlibs");
}


# --- Write a DynaLoader bootstrap file if required

sub mkbootstrap {

=head1 NAME

mkbootstrap

=head1 DESCRIPTION

Make a bootstrap file for use by this system's DynaLoader.
It typically gets called from an extension Makefile.

There is no .bs file supplied with the extension. Instead a _BS file
which has code for the special cases, like posix for berkeley db on the
NeXT.

This file will get parsed, and produce a maybe empty
@DynaLoader::dl_resolve_using array for the current architecture.
That will be extended by $BSLOADLIBS, which was computed by Andy's
extliblist script. If this array still is empty, we do nothing, else
we write a .bs file with an @DynaLoader::dl_resolve_using array, but
without any `if's, because there is no longer a need to deal with
special cases.

The _BS file can put some code into the generated .bs file by placing
it in $bscode. This is a handy 'escape' mechanism that may prove
useful in complex situations.

If @DynaLoader::dl_resolve_using contains -L* or -l* entries then
mkbootstrap will automatically add a dl_findfile() call to the
generated .bs file.

=head1 AUTHOR

Andreas Koenig <k@otto.ww.TU-Berlin.DE>
Tim Bunce <Tim.Bunce@ig.co.uk>
Andy Dougherty <doughera@lafcol.lafayette.edu>

=cut

    my($self, @bsloadlibs)=@_;
    print STDERR "	bsloadlibs=@bsloadlibs\n" if $Verbose;

    # We need DynaLoader here because we and/or the *_BS file may
    # call dl_findfile(). We don't say `use' here because when
    # first building perl extensions the DynaLoader will not have
    # been built when MakeMaker gets first used.
    require DynaLoader;
    import DynaLoader;

    initialize(@ARGV) unless defined $att{'BASEEXT'};

    rename "$att{BASEEXT}.bs", "$att{BASEEXT}.bso";

    if (-f "$att{BASEEXT}_BS"){
	$_ = "$att{BASEEXT}_BS";
	package DynaLoader; # execute code as if in DynaLoader
	local($osname, $dlsrc) = (); # avoid warnings
	($osname, $dlsrc) = @Config::Config{qw(osname dlsrc)};
	$bscode = "";
	unshift @INC, ".";
	require $_;
	shift @INC;
    }

    if ($Config{'dlsrc'} =~ /^dl_dld/){
	package DynaLoader;
	push(@dl_resolve_using, dl_findfile('-lc'));
    }

    my(@all) = (@bsloadlibs, @DynaLoader::dl_resolve_using);
    my($method) = '';
    if (@all){
	open BS, ">$att{BASEEXT}.bs"
		or die "Unable to open $att{BASEEXT}.bs: $!";
	print STDOUT "Writing $att{BASEEXT}.bs\n";
	print STDOUT "	containing: @all" if $Verbose;
	print BS "# $att{BASEEXT} DynaLoader bootstrap file for $Config{'osname'} architecture.\n";
	print BS "# Do not edit this file, changes will be lost.\n";
	print BS "# This file was automatically generated by the\n";
	print BS "# mkbootstrap routine in ExtUtils/MakeMaker.pm.\n";
	print BS "\@DynaLoader::dl_resolve_using = ";
	# If @all contains names in the form -lxxx or -Lxxx then it's asking for
	# runtime library location so we automatically add a call to dl_findfile()
	if (" @all" =~ m/ -[lL]/){
	    print BS "  dl_findfile(qw(\n  @all\n  ));\n";
	}else{
	    print BS "  qw(@all);\n";
	}
	# write extra code if *_BS says so
	print BS $DynaLoader::bscode if $DynaLoader::bscode;
	print BS "\n1;\n";
	close BS;
    }

    # special handling for systems which needs a list of all global
    # symbols exported by a modules to be dynamically linked.
    if ($Config{'dlsrc'} =~ /^dl_aix/){
       my($bootfunc);
       ($bootfunc = $att{EXTMODNAME}) =~ s/\W/_/g;
       open EXP, ">$att{BASEEXT}.exp";
       print EXP "#!\nboot_$bootfunc\n";
       close EXP;
    }
}

# the following keeps AutoSplit happy
package ExtUtils::MakeMaker;
1;

__END__
