package WebService::NiigataUnyu;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;
use Encode;
use WWW::Mechanize;
use Web::Scraper;
use YAML;


# Module implementation here

# コンストラクタ
sub new {
  my $class = shift;
  my $self;
  my $mech = WWW::Mechanize->new();
  $self->{start_url} = 'http://www2.nuis.co.jp/kzz80011.htm';
  $mech->agent_alias( 'Windows IE 6' );
  $self->{mech} = $mech;

  return bless $self, $class;
}
 
# 新潟運輸に問い合わせ
sub check {
  my $self    = shift;
  my $numbers = shift; # 荷物問い合わせ番号のリストのリファレンス
  # フォームの問い合わせは5件ごとなので5件ごとのリストのリストにする
  my $list; # 5件ごとに分割されたリストのリストが入る
  my $j = -1; #添え字調整
  foreach ( my $i = 0; $i < $#$numbers + 1; $i++ ) {
    $j++ unless $i % 5;
    push @{$list->[$j]}, $numbers->[$i];
  }
  # _requestを呼んで実際にWebアクセスする
  my $result = [];
  foreach my $item( @$list ) {
    sleep 5 if $#$result != -1; # 2回目のアクセスの前に5秒ウェイト 
    my $res = _request($self, $item);
    push @$result, @$res; # 返答は最大10件なので、$resultにためていく
  }
  return $result; # 集まったリストを返す
}
 
# 実際にリストからアクセスする
sub _request {
  my $self = shift;
  my $list = shift;
  $self->{mech}->get( $self->{start_url} );
  $self->{mech}->form_name('form1');
  for ( my $i = 0; $i < $#$list + 1; $i++) {
    my $field = sprintf "toino%d", $i+1;
    $self->{mech}->set_fields( $field => $list->[$i]);
  }
  $self->{mech}->click('submit');

  # Web::Scraper による解析
  my $s = scraper {
    #process '//html/body/div[3]/div/div/div[2]/div/table',
    process '//div[3]/div/div/div[2]/div/table',
    'results[]' => scraper {
      process '//tr[1]/td',
      number => 'TEXT',
      process '//tr[7]/td',
      date => [ 'TEXT', sub { s/\s//g; return $_; } ],
      process '//tr[8]/td',
      time => [ 'TEXT', sub { s/\s//g; return $_; } ],
      process '//tr[11]/td',
      status => [ 'TEXT', sub { s/\s//g; return $_; } ],
      process '//tr[3]/td' ,
      items => [ 'TEXT', sub { s/\s//g; return $_; } ],
      process '//tr[9]/td' ,
      shop => [ 'TEXT', sub { s/\s//g; return $_; } ],
    },
  };
  my $res = $s->scrape( 
             $self->{mech}->content() 
            );
  # 得られた結果をリストで返す
  
  my $res2 = [];
  foreach my $item ( @{$res->{results}} ) {
    my $item2 = {};
    foreach my $key ( keys %$item ) {
      $item2->{$key} = encode_utf8( $item->{$key} );
    }
    unless ( $item2->{status} ) {
      $item2->{status} = $item2->{items};
      delete $item2->{items};
    }
    if ( ( exists $item2->{shop} ) && !( $item2->{status} =~ m/配達完了済/ ) ) {
      $item2->{status} = "$item2->{shop} $item2->{status}";
    }
    push @$res2, $item2;
  }
  $res->{results} = $res2;
  return $res->{results};
}
 
sub dump {
  my $self = shift;
  print Dump($self);
  return;
}
 
1; # Magic true value required at end of module
__END__


=encoding utf-8

=head1 NAME

WebService::NiigataUnyu - Check Track Shipments (Niigata Unyu Co.,Ltd. /Japan)


=head1 NAME (ja)

WebService::NiigataUnyu - 新潟運輸 お荷物の配達状況照会へ照会するモジュール


=head1 SYNOPSIS

    use WebService::NiigataUnyu;
    
    my $maruun = WebService::NiigataUnyu->new();
    
    my $res = $maruun->check([
      '000000000001',
      '000000000012',
    ]);
    
    use YAML;
    print Dump( $res );
    

=head1 DESCRIPTION

「お荷物の配達状況照会(お問い合わせ番号) | 新潟運輸株式会社」Webページに、問い合わせ番号を入力し、回答を回収します。


=head1 METHOD
	
=over
	
=item new()

=item check(I<$args>)

=item dump()
	
=back


=head1 DEPENDENCIES

=over

=item L<Encode>

=item L<WWW::Mechanize>

=item L<Web::Scraper>

=item L<YAML>

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-NiigataUnyu@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

OONO Yoshitaka  C<< <aab61120@pop12.odn.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, OONO Yoshitaka C<< <aab61120@pop12.odn.ne.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=cut

