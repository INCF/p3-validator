function quicklog(logfile,msg,varargin)
% log something to the screen & to a logfile
try
    msg = sprintf([hlp_hostname '/' datestr(now) '@' hlp_getcaller ': ' msg '\n'],varargin{:});
    fprintf(msg);
    if ~isempty(logfile)
        try
            % try to create / open the log file
            if ~exist(logfile,'file')
                try
                    % re-create
                    fid = fopen(logfile,'w+');
                    if fid == -1
                        error('Error creating file'); end
                catch
                    % failed: try to create directories
                    try
                        io_mkdirs(logfile,{'+w','a'});
                    catch
                        disp(['Could not create logfile directory: ' fileparts(logfile)]);
                    end
                    % try to create file
                    try
                        fid = fopen(logfile,'w+');
                        if fid == -1
                            error('Error creating file'); end
                    catch
                        disp(['Could not create logfile ' logfile]);
                    end
                end
            else
                % append
                fid = fopen(logfile,'a');
                if fid == -1
                    error('Error creating file'); end
            end
        catch
            disp(['Could not open logfile ' logfile]);
        end
        % write message
        try
            fprintf(fid,msg);
        catch
            disp(['Could not write to logfile ' logfile]);
        end
        % close file again
        try
            fclose(fid);
        catch
        end
    end
catch
    disp('Invalid logging parameters.');
end
