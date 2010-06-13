package Dist::Zilla::PluginBundle::DOY;
use Moose;
# ABSTRACT: Dist::Zilla plugins for me

use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 SYNOPSIS

  # dist.ini
  [@DOY]
  dist = Dist-Zilla-PluginBundle-DOY

=head1 DESCRIPTION

My plugin bundle. Roughly equivalent to:

    [@Basic]

    [MetaConfig]
    [MetaJSON]

    [NextRelease]
    format = %-5v %{yyyy-MM-dd}d

    [PkgVersion]

    [PodCoverageTests]
    [PodSyntaxTests]
    [NoTabsTests]
    [EOLTests]
    [CompileTests]

    [Repository]
    git_remote = git://github.com/doy/${lowercase_dist}
    github_http = 0

    [Git::Check]
    allow_dirty =
    [Git::Tag]
    tag_format = %v
    tag_message =
    [BumpVersionFromGit]
    version_regexp = ^(\d+\.\d+)$
    first_version = 0.01

    [PodWeaver]

=cut

has dist => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->dist =~ /^Task-/ ? 1 : 0 },
);

has is_test_dist => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->dist =~ /^Foo-/ ? 1 : 0 },
);

has github_url => (
    is  => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $dist = $self->dist;
        $dist = lc($dist);
        "git://github.com/doy/$dist.git";
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = $class->$orig(@_);
    return { %{ $args->{payload} }, %{ $args } };
};

sub configure {
    my $self = shift;

    if ($self->is_test_dist) {
        $self->add_bundle(
            '@Filter' => { bundle => '@Basic', remove => ['UploadToCPAN'] }
        );
        $self->add_plugins('FakeRelease');
    }
    else {
        $self->add_bundle('@Basic');
    }

    $self->add_plugins(
        'MetaConfig',
        'MetaJSON',
        ['NextRelease' => { format => '%-5v %{yyyy-MM-dd}d' }],
        'PkgVersion',
        'PodCoverageTests',
        'PodSyntaxTests',
        'NoTabsTests',
        'EOLTests',
        'CompileTests',
        ['Repository' => { git_remote => $self->github_url, github_http => 0 }],
        ['Git::Check' => { allow_dirty => '' }],
        ['Git::Tag'   => { tag_format => '%v', tag_message => '' }],
        ['BumpVersionFromGit' => { version_regexp => '^(\d+\.\d+)$', first_version => '0.01'}],
        'PodWeaver',
    );

    $self->add_plugins('TaskWeaver') if $self->is_task;
}

=head1 SEE ALSO

L<Dist::Zilla>
L<Task::BeLike::DOY>

=begin Pod::Coverage

  configure

=end Pod::Coverage

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
