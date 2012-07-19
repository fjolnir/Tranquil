sub fibonacci
{
   my $number = shift;  # get the first argument

   if ( $number < 2 ) { # base case
      return $number;
   } 

   else {                                # recursive step
      return fibonacci( $number - 1 ) + fibonacci( $number - 2 );
   }
}


print(fibonacci(35));