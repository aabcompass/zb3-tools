clear all;
% setup parameters
n_ecasic=6;
dimx_ecasic = 8;
dimy_ecasic = (48+12);
ipaddr = '192.168.7.10';
port = 23;

fix_color_map = 0;
colorbar_lim = 0.0001;%45 %установить предел цветовой шкалы / set colorbar limit
% 
do_remap = 0;
integration = 50000;
run_once = 0;
pause_val=0.02;
lovosero_mode = 1;

%open tcp connection
t = tcpip(ipaddr, port, 'NetworkRole', 'client', 'InputBufferSize', 10000); 
t.InputBufferSize=100000;
fopen(t);

% %determine version
% 'sending'
% fwrite(t, 'instrument ver');
% [msg_reply, count] = fread(t, 31); 
% 'ok\n'
% if strfind(char(msg_reply'), 'v3.') ~= 0
%     protocol_ver = 3
% else
%     protocol_ver = 2
% end
%

fwrite(t, 'instrument mode live');
[msg_reply, count] = fread(t, 3); 

flushinput(t);


% 2 graphics
a1=subplot(7,1,1:6);
a2=subplot(7,1,7);



for j=1:100000
    % acquire one frame
    fwrite(t, 'acq live');
    pdm_data0 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 1');
    pdm_data1 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 2');
    pdm_data2 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 3');
    pdm_data3 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 4');
    pdm_data4 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 5');
    pdm_data5 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 6');
    pdm_data6 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    fwrite(t, 'acq next 7');
    pdm_data7 = fread(t, 2880/8, 'uint32');
    pause(pause_val);
    pdm_data = [pdm_data0; pdm_data1; pdm_data2; pdm_data3; pdm_data4; pdm_data5; pdm_data6; pdm_data7];
    pdm_data = swapbytes(uint32(pdm_data));
    ecasics_2d = reshape(pdm_data, [dimx_ecasic dimy_ecasic n_ecasic]); 
    % concatenation of 6 images into one image 48x48
    if lovosero_mode == 0
        pdm_2d = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)' ecasics_2d(:,:,3)' ecasics_2d(:,:,4)' ecasics_2d(:,:,5)' ecasics_2d(:,:,6)'];
    else
        pdm_2d = [ecasics_2d(:,:,3)' ecasics_2d(:,:,6)'];        
    end
    % plot 2D image
    clims = [0 colorbar_lim];
    
    
    for i = 1:n_ecasic % 6
         pdm_2d_pc((i-1)*8+1:i*8,:) = pdm_2d((i-1)*10+1:i*10-2,:); %показания с прибора
         pdm_2d_ki(i,:) = pdm_2d(i*10-1,:);
    end
    
    if fix_color_map==1
        %imagesc(a1,double(pdm_2d_remap/50000), clims);
        gca = imagesc(a1,double(pdm_2d_pc)/integration, clims);colorbar(a1);
        set(a1,'DataAspectRatio',[1 1 1])
        %gca = imagesc(a2,double(pdm_2d_ki)/integration, clims);colorbar;
        %set(gca,'DataAspectRatio',[1 1 1])
    else
        gca = imagesc(a1,double(pdm_2d_pc)/integration);colorbar(a1);
        set(gca,'DataAspectRatio',[1 1 1])
        %gca = imagesc(a2,double(pdm_2d_ki)/integration);colorbar;
        %set(gca,'DataAspectRatio',[1 1 1])
    end
    
    %if(j==1)
        colorbar;
    %end
    pause(pause_val)   %0.1sec
    if run_once == 1
       break;
    end
end
cd ..

%% close tcp
fclose(t);
'port closed'
