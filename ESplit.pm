
		#############################################################################
		#																			#
		# 	ESplit - Modul zum Zerlegen von Strings an frei w�hlbaren 				#
		#			 Zeichen, Strings oder REn.										#
		#																			#
		#	Copyright (c) 2000 by Hartmut Camphausen <h.camp@creagen.de>.			#
		#	Alle Rechte vorbehalten.												#
		#	Dieses Modul ist freie Software. Es kann zu den gleichen Bedingungen	#
		#	genutzt, ver�ndert und weitergegeben werden wie Perl selbst.			#
		#																			#
		#############################################################################

	package ESplit;

	require 5.005;
	
	use strict;
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = "1.00";

	use Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw(e_split);
	
	
	# e_split																				
	#																						
    # split-et 1 String an frei w�hlbaren Zeichen(ketten), liefert einen Array mit			
    # den Daten zwischen den Trennern:														
    #																						
    #		my @tokens		= e_split ('split_here', $string, num_of_elements, flags);		
	#		my $tokens_ref	= e_split ('split_here', $string, num_of_elements, flags);		
    #																						
    # Trenner, die in einem "'-umschlossenen String stehen, werden ignoriert.				
    # \-escapte Trenner bzw. "'\ werden ignoriert (d.h. nicht behandelt).					
    #																						
    # rein: - [Trenner] 				kann eine Regex sein (ohne /../)					
    #		- [, Quellstring | Ref auf Quellstring] 										
    #		- [, [-]n] 					(Anzahl der zu liefernden Elemente -=von hinten)	
    #		- [, 1|2] 					(H�kchen/Escapezeichen vor Trenner beibehalten (1),	
    #									study() �ber Quellstring ausf�hren (2))				
    # raus: Ergebnisarray (Arraykontext) | Ref auf Ergebnisarray (Skalarkontext)			
    #																						
    # Wird die Trenner-RE (Parameter #1)in () gegeben, liefert e_split den gematchten 		
    # Trenner als n+1tes Element des Ergebnisarrays (wie split).							
    #																						
    # RE:	. liefert leeren Array (wie split)												
    # 		'' (Leerstring) liefert jedes Zeichen (wie split)								
    # 		   (H�kchen sind normale Zeichen)												
    #		'()' (Leerstring in Klammern) liefert jedes Zeichen, plus dieses als Trenner	
    #		   (H�kchen sind normale Zeichen)												
    # 		undef trennt an Leerzeichen (\s+) (wie split)									
    #          (H�kchen werden als Stringumschlie�er\Escaper interpretiert)					
    #																						
    # CAVE: Evaluiert die Trenner-RE zu einem Leerstring (bspw. '.*'), l�uft e_split 		
    #		/ziemlich/ lange :-(															
	#																						
    # Wird e_split ohne alles aufgerufen, trennt es $_ an \s+ auf. Bei gegebenem			
    # Parameter #2 wirkt RE = undef wie RE = "\s+".											
    #																						
    # Soll e_split eine bestimmte Anzahl von Feldern extrahieren (Parameter #3),			
    # werden diese in aufsteigender Folge geliefert. $Ergebnisarray[-1] enth�lt				
    # gegebenenfalls den Reststring.														
    # Bei negativem Parm #3 wird der Ergebnisarray *nicht* auf den Kopf gestellt 			
    # (das �berlassen wir dem geneigten User). Der Reststring findet sich gegebenenfalls	
    # in $Ergebnisarray[0].																	
    #																						
    # Standardm��ig werden feldumschlie�ende H�kchen entfernt, ditto werden escapete		
    # Trenner in *nicht* gequoteten Feldern unescaped.										
    # Enth�lt ein gequotetes Feld escapete H�kchen, wie sie zum Quoten verwendet wurden, 	
    # werden diese unescaped.																
    # Setzt man Bit 0 von Parameter #4 (Parm #4 & 1 == 1), werden H�kchen nicht entfernt,	
    # und es wird nichts unescapet.															
    # - Wird Parameter 3 auf einen Wert <> 0 gesetzt, enth�lt das letzte (bzw. erste)		
    #	Feld des Ergebnisarrays den *unbehandelten* Rest-String. Dies gilt auch dann, wenn	
    #	der Quellstring zuf�llig genau so viele Elemente enthielt, wie angefordert wurden!	
    #																						
    # Ist Bit 1 von Parameter #4 gesetzt (Parm #4 & 2 == 2), wird vor der Extraktion 		
    # ein study() �ber den Quellstring ausgef�hrt.											
    #																						
    # Escapen:																				
    # Trenner oder f�hrende/folgende H�kchen k�nnen \-escaped werden, um sie au�er Funktion	
    # zu setzen.																			
    # Sollen Escapezeichen vor Trennern oder f/f-H�kchen nicht auf diese wirken, sollten	
    # sie ihrerseits \-escaped werden.														
    #																						
    # Trennverhalten mit H�kchen:															
    # Als umschlie�end werden nur gleichartige (" oder ') H�kchen akzeptiert.				
    # (Mischformen sind f�r parse_line �brigens t�dlich. Wamm.)								
    # Gequotete Felder erkennt e_split an der Folge (^|trenner)"'...."'(trenner|$).			
    # D.h., ein �ffnendes H�kchen wird *nicht* als Feldumschlie�er behandelt, wenn zwischen 
    # dem 'schlie�enden' H�kchen und dem folgenden Trenner noch etwas steht.				
    # Die Sequenz																			
    #																						
    #		...TRENNER"Feld"datenTRENNER...													
    #																						
    # wird als 																				
    #																						
    #		"Feld"daten																		
    #																						
    # geliefert. (anders als bei parse_line wird das mittige H�kchen nicht als				
    # Trennersurrogat bzw. beginnendes Quoting *innerhalb* des Tokens akzeptiert.)			
    #																						
    # Seltsame Feldbildungen k�nnen resultieren, wenn nicht gequotete Quelldaten			
    # in der Folge																			
    #																						
    # 		...TRENNER"Daten von Feld1TRENNERDaten von Feld2"TRENNER...						
    #																						
    # vorliegen. Das f�hrende H�kchen von Feld1 wird identifiziert, e_split sucht den 		
    # String auf die schlie�ende Sequenz ("TRENNER) ab - und wird am Ende von Feld2 f�ndig.	
    # Hmmm.																					
    #																						
    # Abhilfe																				
    #	mu� bei der Datenerzeugung stattfinden. Man escape alle f�hrenden oder folgenden	
    #	H�kchen, oder man quote alle (verd�chtigen?) Felder.								
    #																						
    # Schwierig wird's, wenn die Felddaten selber die �ffnende/schlie�ende Sequenz enthalten
    # k�nnen. W�hrend das Quoten normalerweise die Funktion des Trenner-Escapens �bernimmt	
    # (was man nat�rlich alternativ auch machen kann), kann man hier sich behelfen,			
    # indem man in den Felddaten enthaltene Trenner \-escaped.								
    #																						
    # Diskussion:																			
    # e_split vs. Text::quote_words															
    #																						
    # Text::quote_words() bedient sich der Routine parse_line() zum Stringzerlegen.			
    # Die folgenden Anmerkungen beziehen sich auf parse_line als Kernfunktion.				
    #																						
    # 1.	e_split ist zwischen 2,5 (kurze Strings) und f�nf mal (lange Strings) schneller	
    #		als parse_line																	
    # 2.	e_split verh�lt sich hinsichtlich der Behandlung von Quotingzeichen plausibler	
    #		als parse_line (siehe "Trennverhalten mit H�kchen" weiter oben)					
    # 3.	e_split vertr�gt Mischformen (bspw. doppelte H�kchen vorne, einfaches hinten).	
    #		parse_line liefert beim Auftreten solcher Kombis einen leeren Array				
    #																						
    # TODO: - eine effizientere Methode (RE), um n Elemente vom Ende des Strings zu liefern	
    # 		- single/double quotes der Trenner (-RE) unterscheiden?							
    #		- usf.?																			
    sub e_split {
		local $^W = 0;
    	my ($sep, $str, $stop_at, $flags) 	= @_;
		$sep 								= '\s+'	unless defined $sep;
    	$str 								= $_	unless defined $str;
    	$str 								= ${$str}
    		if (ref $str eq 'SCALAR');

    	($stop_at, my $from_end)			= $stop_at < 0 ? (0, abs ($stop_at)) : (abs ($stop_at), 0);
    	$stop_at ++ 						if $stop_at 	== 1;
    	$from_end++							if $from_end	== 1;
    	
    	$flags								= 0		unless defined $flags;
    	my $include_sep 					= ($sep =~ s/^\(// && $sep =~s/\)$//);

    	my $elems_found						= 1;
    	my $remainder						= 0;
    	my @vals;
		my $l_end;

		if (($sep eq '.') || ($sep eq '.*')) {
			return wantarray ? @vals : \@vals;
		}
    	if ($sep eq '') {
			@vals = $include_sep ?  $str =~ /((.))/g 
								 :  $str =~/(.)/g;
			return 	wantarray	 ? @vals : \@vals;
		}

		study ($str) if ($flags & 2);
		if ($include_sep) {
			while ($str =~ s/(?:((["']).*?(?<!\\)(?>\\{2})*\2)($sep|$))|(?:(.*?(?<!\\)(?>\\{2})*)($sep))//s) {
				$l_end = (length $3) || (length $5);
				push @vals, defined $3 ? ($1, $3) : ($4, $5);
				unless (++$elems_found ^ $stop_at) {
					$remainder = length $str;last;
				}
			}
		}else {
			while ($str =~ s/(?:((["']).*?(?<!\\)(?>\\{2})*\2)($sep|$))|(?:(.*?(?<!\\)(?>\\{2})*)($sep))//s) {
				$l_end = (length $3) || (length $5);
				push @vals, defined $3 ? $1 : $4;
				if (++$elems_found == $stop_at) {
					$remainder = length $str;last;
				}
			}
		}
		if ($l_end) {
			push @vals, $str;
		}elsif ($include_sep){
			pop @vals;
		}

		my $m_elem		= $stop_at  || $from_end || $elems_found;
		$m_elem			= $m_elem * 2					if $include_sep;
		$m_elem			= @vals 	+ $include_sep + 1	if $m_elem  >= @vals;
		$m_elem			= $m_elem	- $include_sep - 1	if $m_elem;

		my ($l_index, $r_index);
		if ($from_end) {
			$l_index = @vals - $m_elem;
			$r_index = $#vals
		}else{
			$l_index = 0;
			$r_index = $m_elem - ($remainder > 0) - 1;
		}
		
		unless ($flags & 1) {
			foreach my $item (@vals[$l_index..$r_index]) {
				if ($item =~ /^(["'])/ && $item =~ /(?<!\\)$1$/) {
					$item =~ s/^(["'])//;
					$item =~ s/\\($1)/$1/g;
					$item =~ s/$1$//;
				}else{
					$item =~ s/\\((?>\\{2})*$sep)/$1/g;
				}
			}
		}

		if ($from_end && $l_index) {
			splice @vals, 0, $l_index, join $include_sep ? '' : $sep, @vals[0..$l_index-1]; 
		}

		return wantarray ? @vals : \@vals;
	}
