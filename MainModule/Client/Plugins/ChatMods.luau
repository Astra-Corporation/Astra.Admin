return function(Vargs,GetEnv)
	local client, service = Vargs.Client, Vargs.Service
	local Functions = client.Functions
	local Variables = client.Variables
	local shark = [=[
	                           .^:;.                        
                              ,!>!^                         
                             "!i>!'                     ',, 
                            ^l><l,                    .:>I' 
                          ."<++<i"                   ^~~;.  
                    ...'`^,Ii_]_!"          .       ;+>I'   
       ..''``^^""",,,,,,,,,,,:;;:,"..      ^~   .'^;++!`    
   '^";;:;:::,:::,,:::::;;;;;;;;II;,";!;,:ii!::;;+!i_-!:.   
 .I<<IIlIIlIII;;;IIII!!!!!!iii>>ii!II;I>~~!+~>;l;:;^"-}[>`  
 .i+~++<illi>ii>><<<<~+~~~<<<>>iii>IIl;:-!!i;I,:"'    .">+` 
  ';~-[?]]}[}}?-?-+-_--_~~++_~>ili!IIl;,;;;:,`'.            
	..`^"",!}[??]?+?--]-_+_++~!i;I;;::,^^`'.                
       ......'``^^^",:I!_]]]-~il^`'..                       
          ....''...'''''']}}?]~i".                          
              ...''''''``^>?_-_->l,`.                       
                            .`:;<+_~<>;:`                   
                                 ...''.. 
                              :: Astra v3 ::
	]=]

	print(shark)

end