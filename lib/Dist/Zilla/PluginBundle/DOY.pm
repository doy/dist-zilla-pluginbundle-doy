package Dist::Zilla::PluginBundle::DOY;
use Moose;
# ABSTRACT: Dist::Zilla plugins for me

use List::MoreUtils qw(any);

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
    [CheckChangesHasContent]

    [PkgVersion]

    [PodCoverageTests]
    [PodSyntaxTests]
    [NoTabsTests]
    [EOLTests]
    [Test::Compile]

    [Repository]
    git_remote = github ; or origin, if github doesn't exist

    [Git::Check]
    allow_dirty =
    [Git::Tag]
    tag_format = %v
    tag_message =
    [Git::NextVersion]
    version_regexp = ^(\d+\.\d+)$
    first_version = 0.01

    [PodWeaver]

=cut

has dist => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has awesome => (
    is  => 'ro',
    isa => 'Str',
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
    default => sub {
        my $self = shift;
        return 1 if $ENV{DZIL_FAKE_RELEASE};
        return $self->dist =~ /^Foo-/ ? 1 : 0
    },
);

has git_remote => (
    is  => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        return '' unless -d '.git';
        my @remotes = `git remote`;
        chomp @remotes;
        return 'github' if any { $_ eq 'github' } @remotes;
        return 'origin';
    },
);

has _plugins => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [
            qw(
                GatherDir
                PruneCruft
                ManifestSkip
                MetaYAML
                License
                Readme
                ExtraTests
                ExecDir
                ShareDir
            ),
            ($self->awesome ? $self->awesome : 'MakeMaker'),
            qw(
                Manifest
                TestRelease
                ConfirmRelease
                MetaConfig
                MetaJSON
                NextRelease
                CheckChangesHasContent
                PkgVersion
                PodCoverageTests
                PodSyntaxTests
                NoTabsTests
                EOLTests
                Test::Compile
                Repository
                Git::Check
                Git::Commit
                Git::Tag
                Git::NextVersion
            ),
            ($self->is_task      ? 'TaskWeaver'  : 'PodWeaver'),
            ($self->is_test_dist ? 'FakeRelease' : 'UploadToCPAN'),
        ]
    },
);

has plugin_options => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my %opts = (
            'NextRelease'        => { format => '%-5v %{yyyy-MM-dd}d' },
            'Repository'         => {
                git_remote  => $self->git_remote,
            },
            'Git::Check'         => { allow_dirty => '' },
            'Git::Tag'           => { tag_format => '%v', tag_message => '' },
            'Git::NextVersion' => {
                version_regexp => '^(\d+\.\d+)$',
                first_version  => '0.01'
            },
            'Git::Commit' => {
                commit_msg => 'changelog',
            },
        );

        for my $option (keys %{ $self->payload }) {
            next unless $option =~ /^([A-Z][^_]*)_(.+)$/;
            my ($plugin, $plugin_option) = ($1, $2);
            $opts{$plugin} ||= {};
            $opts{$plugin}->{$plugin_option} = $self->payload->{$option};
        }

        return \%opts;
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

    $self->add_plugins(
        [ 'Prereqs' => 'TestMoreDoneTesting' => {
            -phase       => 'test',
            -type        => 'requires',
            'Test::More' => '0.88',
        } ]
    );
    $self->add_plugins(
        map { [ $_ => ($self->plugin_options->{$_} || {}) ] }
            @{ $self->_plugins },
    );
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-dist-zilla-pluginbundle-doy at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-DOY>.

=head1 SEE ALSO

L<Dist::Zilla>
L<Task::BeLike::DOY>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Dist::Zilla::PluginBundle::DOY

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-DOY>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-DOY>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-DOY>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-DOY>

=back

=begin Pod::Coverage

  configure

=end Pod::Coverage

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
