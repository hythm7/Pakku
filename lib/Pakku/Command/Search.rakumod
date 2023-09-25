use Pakku::Log;
use Pakku::Spec;
use Pakku::Meta;

unit role Pakku::Command::Search;

multi method fly (

           'search',
           :@spec!,
    Int:D  :$count   = 666,
    Bool:D :$relaxed = True,
    Bool:D :$details = False,

  ) {


  spinner.header: 'SRC';
  spinner.activate;

  my $promise = start sink @spec
    ==> map( -> $spec { Pakku::Spec.new: $spec                        } )
    ==> map( -> $spec { self!recman.search( :$spec :$relaxed :$count ).Slip   } )
    ==> grep( *.defined                                            )
    ==> map( -> $meta { Pakku::Meta.new( $meta ).gist: :$details } )
    ==> map( -> $meta { out $meta unless self!dont } );

  until $promise.status { spinner.next; sleep 0.1 }

  spinner.deactivate;

}

