return function(Vargs,GetEnv)
	local client, service = Vargs.Client, Vargs.Service
	local Functions = client.Functions
	local Variables = client.Variables
  local BuildInfo = Variables.BuildInfo
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
                    Running Astra V3 Compiled %s %s@%s                        
  ]=]
print(string.format(shark,BuildInfo.BUILD_DATE,BuildInfo.COMMIT,BuildInfo.BRANCH))

end