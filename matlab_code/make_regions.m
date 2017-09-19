function [region] = make_regions(vect)
% Crea una matrice così suddivisa:
%   - tutti i blocchi appartenenti ad una stessa regione sono sulla stessa
%     riga, quindi ad ogni riga corrisponde una diversa regione
%bisogna aggiungere la parte sul riconoscimento del falso/vero allarme e
%quindi cambiare i colori dei bordi
global  numWregions;

k = 0; %numero della regione
found = false;
region = zeros(1,1);

if size(vect,1) > 0
    for i=1:size(vect,2)
        num_reg = vect(i);

        if not(isempty((find(region == num_reg))))
            found = true;
        end

        if found    

            last = find(region == num_reg, 1);

            if isempty(find(region == num_reg-1, 1)) && not(isempty(find(vect == num_reg-1,1))) && rem(num_reg-1,numWregions)~=0 %Sx
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg-1;
            end

            if isempty(find(region == num_reg+1, 1)) && not(isempty(find(vect == num_reg+1,1))) && rem(num_reg,numWregions)~=0 %Dx
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg+1;
            end

            if isempty(find(region == num_reg-numWregions, 1)) && not(isempty(find(vect == num_reg-numWregions,1))) %Up
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg-numWregions;
            end

            if isempty(find(region == num_reg+numWregions, 1)) && not(isempty(find(vect == num_reg+numWregions,1))) %Down
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg+numWregions;
            end
        else   
            if  k > 0
                    if (not(isempty(find(region == num_reg-1, 1))) && rem(num_reg-1,numWregions)~=0) || (not(isempty(find(region == num_reg+1, 1))) && rem(num_reg,numWregions)~=0) || (not(isempty(find(region == num_reg-numWregions, 1))) && num_reg > numWregions) || not(isempty(find(region == num_reg+numWregions, 1)))
                        if not(isempty(find(region == num_reg-1, 1))) && rem(num_reg-1,numWregions)~=0
                            sx = find(region == num_reg-1, 1);
                        else
                            sx = 0;
                        end
                        if not(isempty(find(region == num_reg+1, 1))) && rem(num_reg,numWregions)~=0
                            dx = find(region == num_reg+1, 1);
                        else
                            dx = 0;
                        end
                        if isempty(find(region == num_reg-numWregions, 1))
                            up = 0;
                        else
                            up = find(region == num_reg-numWregions, 1);
                        end
                        if isempty(find(region == num_reg+numWregions, 1))
                            dw = 0;
                        else
                            dw = find(region == num_reg+numWregions, 1);
                        end
                        
                        last = max(sx,max(dx,max(up,dw)));
                        
                        if rem(last,size(region,1))==0
                            k_new = size(region,1);
                        else
                            ok = last;
                            while ok > size(region,1)
                                ok = ok - size(region,1);
                            end
                            k_new = ok;
                        end
                        z_new = size(region,2);
                        while region(k_new,z_new)==0
                           z_new = z_new - 1; 
                        end
                        z_new = z_new +1;
                        
                        region(k_new,z_new) = num_reg;
                    else
                        z = 1;
                        k = size(region,1) + 1;
                        region(k,z) = num_reg;
                    end
            else
                z = 1;
                k = 1;
                region(k,z) = num_reg;
            end          
        
        last = find(region == num_reg, 1);
        
            if not(isempty(find(vect == num_reg-1, 1))) && rem(num_reg-1,numWregions)~=0 && isempty(find(region == num_reg-1, 1)) %Sx
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg-1;
            end

            if not(isempty(find(vect == num_reg+1, 1))) && rem(num_reg,numWregions)~=0 && isempty(find(region == num_reg+1, 1)) %Dx
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg+1;
            end

            if not(isempty(find(vect == num_reg-numWregions, 1))) && isempty(find(region == num_reg-numWregions, 1)) %Up
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg-numWregions;
            end

            if not(isempty(find(vect == num_reg+numWregions, 1))) && isempty(find(region == num_reg+numWregions, 1)) %Down
                if rem(last,size(region,1))==0
                    k_new = size(region,1);
                else
                    ok = last;
                    while ok > size(region,1)
                        ok = ok - size(region,1);
                    end
                    k_new = ok;
                end
                z_new = size(region,2);
                while region(k_new,z_new)==0
                   z_new = z_new - 1; 
                end
                z_new = z_new +1;
                
                region(k_new,z_new) = num_reg+numWregions;
            end
        end
        
        found = false;
    end
end
end