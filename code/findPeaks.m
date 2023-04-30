function events = findPeaks(dff1, Ca, greenFile, thr, savePeaks, outputPath)

    [~, name, ~] = fileparts(greenFile);

    [m,T] = size(dff1);

    events = {};
    fid = fopen(fullfile(outputPath, strcat(name, "_events.csv")), "w");
    fprintf(fid, '%s,%s\n', "ROI", "event_second");

    for ii = 1:m
        tmp = find(max(Ca{ii})>thr);

        spks = tmp(diff([1 (tmp)])>=10);

        if ~isempty(spks) && spks(1)~= tmp(1)
            spks = [tmp(1) spks];
        end

        events{ii} = spks;

        for spk = spks
            fprintf(fid, '%d,%d\n', ii, spk/10);
        end
    end

    fclose(fid);

    %{
    try
      fig=figure;
      plot_counter = 0;
      for ii = 1:m
        plot(1:T,dff1(ii,:)+plot_counter,'b')
        hold on
        spks = events{ii};
        plot([spks; spks],[repmat(min(dff1(:))+plot_counter,1,numel(spks)); repmat(max(dff1(:))+plot_counter,1,numel(spks))],'r')
        plot_counter = plot_counter+max(max(dff1))-min(min(dff1));
      end

      ylim([min(min(dff1)) plot_counter])
      ticc = max(max(dff1))-min(min(dff1));
      yticks(max(max(dff1)):ticc:ticc*m)
      yticklabels(1:1:m)
      xlim([1 size(dff1,2)])
      set(gca,'Fontsize',10)
      title(['threshold: ',num2str(thr)], 'Fontsize', 20)% ,height: ', num2str(height)])

      %set(gcf,'Position',1.0e+03 *[0.0010    0.0410    2.5600    1.3273])
      %set(gcf,'PaperPosition',[0 0 80 m])



      figname = fullfile(outputPath,[name,'_events.jpg']);
      saveas(fig, figname);
      close(fig);
    catch
    end
    %}

    if savePeaks
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end
        save(fullfile(outputPath, [name '_events.mat']), 'events', '-v6');
    end


end
