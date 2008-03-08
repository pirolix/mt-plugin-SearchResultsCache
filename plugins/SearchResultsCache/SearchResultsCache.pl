package MT::Plugin::OMV::SearchResultsCache;
#   SearchResultsCache - Cache the searched results keyed to search queries in mt-search.cgi
#           Original Copyright (c) 2008 Piroli YUKARINOMIYA
#           Open MagicVox.net - http://www.magicvox.net/
#           @see http://www.magicvox.net/archive/2008/03082243/

use strict;
use Cache::File;
#use Data::Dumper;#DEBUG

# default expire time of cached content
use constant DEFAULT_EXPIRE =>          '7 days';

use vars qw( $MYNAME $VERSION );
$MYNAME = 'SearchResultsCache';
$VERSION = '1.0.0';

use base qw( MT::Plugin );
my $plugin = new MT::Plugin ({
        name => $MYNAME,
        version => $VERSION,
        author_name => 'Piroli YUKARINOMIYA',
        author_link => 'http://www.magicvox.net/',
        doc_link => 'http://www.magicvox.net/archive/2008/03082243/',
        description => <<HTMLHEREDOC,
Cache the searched results keyed to search queries in mt-search.cgi.
Cache-$Cache::VERSION is installed.
HTMLHEREDOC
});
MT->add_plugin( $plugin );

sub instance { $plugin }



### Override searching method
require MT::App::Search;
no warnings qw( redefine );

my $sub_original = \&MT::App::Search::execute;
*MT::App::Search::execute = sub {
	my( $app ) = @_;

    ### Initialize cache component
    my $cache = Cache::File->new(
            cache_root => &get_cache_dir,
            lock_level => Cache::File::LOCK_LOCAL(),
            cache_depth => 2,
    ) or $app->error( __PACKAGE__. ': Failed to initialize Cache::File class' );
    ### Generate a cache-key from query string
    my $q = $app->{query};
    my $cache_key = join "\n", map { join ',', $_, $q->param( $_ ) } sort $q->param;
    ### If cache hit, give the cached content and terminate here
    if( defined( my $cached_content = $cache->get( $cache_key ))) {
        return $cached_content;
    }

    ### Do searching with proper methods
    my $content = $sub_original->( @_ ) or return;
    # and store the retrieved content into cache component
    $cache->set( $cache_key, $content, DEFAULT_EXPIRE );

    $content;
};

### Retrieve path that cache stored
sub get_cache_dir {
    my $path = &instance->{full_path};
    -d $path
        ? "${path}/$MYNAME" # ex) /plugins/SearchResultsCache/SearchResultsCache
        : "${path}.cache";  # ex) /plugins/SearchResultsCache.cache
}

1;