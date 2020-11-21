classdef ParticleDetection < vision.labeler.AutomationAlgorithm
    
    %----------------------------------------------------------------------
    % Step 1: Define required properties describing the algorithm. This
    %         includes Name, Description and UserDirections.
    properties(Constant)
        
        % Name: Give a name for your algorithm.
        Name = 'Custom Algorithm for particle detection';
        
        % Description: Provide a one-line description for your algorithm.
        Description = 'This in an example of a Custom Algorithm for particle detection, where Apps have been used to generate the algorithm';
        
        % UserDirections: Provide a set of directions that are displayed
        %                 when this algorithm is invoked. The directions
        %                 are to be provided as a cell array of character
        %                 vectors, with each element of the cell array
        %                 representing a step in the list of directions.
        UserDirections = {...
            ['Automation algorithms are a way to automate manual labeling ' ...
            'tasks. This AutomationAlgorithm is a template for creating ' ...
            'user-defined automation algorithms. Below are typical steps' ...
            'involved in running an automation algorithm.'], ...
            ['Run: Press RUN to run the automation algorithm. '], ...
            ['Review and Modify: Review automated labels over the interval ', ...
            'using playback controls. Modify/delete/add ROIs that were not ' ...
            'satisfactorily automated at this stage. If the results are ' ...
            'satisfactory, click Accept to accept the automated labels.'], ...
            ['Change Settings and Rerun: If automated results are not ' ...
            'satisfactory, you can try to re-run the algorithm with ' ...
            'different settings. In order to do so, click Undo Run to undo ' ...
            'current automation run, click Settings and make changes to ' ...
            'Settings, and press Run again.'], ...
            ['Accept/Cancel: If results of automation are satisfactory, ' ...
            'click Accept to accept all automated labels and return to ' ...
            'manual labeling. If results of automation are not ' ...
            'satisfactory, click Cancel to return to manual labeling ' ...
            'without saving automated labels.']};
    end
    
    %---------------------------------------------------------------------
    % Step 2: Define properties to be used during the algorithm. These are
    % user-defined properties that can be defined to manage algorithm
    % execution.
    properties
        
        %------------------------------------------------------------------
        % Place your code here
        
        %SelectedLabelName Selected label name
        %   Name of selected label. Particles detected by the algorithm will
        %   be assigned this variable name.
        SelectedLabelName
        
        Sensitivity = 0.97; % In finding circles
        
        radiusRange = [23 45];
        
        Mr = 1.2; % Magnify particle size
        
        nearness_factor = 0.7; % Less than 1. The minimum distance between 2 centers is 2*smallest_radius. Reducing it further by multiplying it by 'factor'.
        
        metric_overlap_threshold = 0.2; % Accumulator Threshold to remove overlapping particles
        
        %------------------------------------------------------------------
        
        
    end
    
    %----------------------------------------------------------------------
    % Step 3: Define methods used for setting up the algorithm.
    methods
        
        function isValid = checkLabelDefinition(~, labelDef)
            
            % Only Rectangular ROI Label definitions are valid for the
            % Vehicle Detector.
            isValid = labelDef.Type==labelType.Rectangle;
        end
        
        function initialize(algObj, ~)
            
            % Store the name of the selected label definition. Use this
            % name to label the detected vehicles.
            algObj.SelectedLabelName = algObj.SelectedLabelDefinitions.Name;
            
        end
        
        function settingsDialog(algObj)
            
            % Input descriptions
            prompt={...
                'Sensitivity',...
                'radius_low',...
                'radius_high',...
                'Increase box size'
                };
            % defaultAnswer should be a cell of strings.
            defaultAnswer={...
                num2str(algObj.Sensitivity),...
                num2str(algObj.radiusRange(1)),...
                num2str(algObj.radiusRange(2)),...
                num2str(algObj.Mr)
                
                };
            
            name='Settings for particle detection';
            numLines=1;
            
            allValid = false;
            while(~allValid)  % Repeat till all inputs pass validation
                
                % Create the settings dialog
                options.Resize='on';
                options.WindowStyle='normal';
                options.Interpreter='none';
                answer = inputdlg(prompt,name,numLines,defaultAnswer,options);
                
                if isempty(answer)
                    % Cancel
                    break;
                end
                
                try
                    % Parse and validate inputs
                    algObj.Sensitivity = str2double(answer{1});
                    algObj.radiusRange(1) = str2double(answer{2});
                    algObj.radiusRange(2) = str2double(answer{3});
                    algObj.Mr = str2double(answer{4});
                    allValid = true;
                catch ALL
                    waitfor(errordlg(ALL.message,'Invalid settings'));
                end
            end
        end
        
    end
    
    %----------------------------------------------------------------------
    % Step 4: Specify algorithm execution. This controls what happens when
    %         the user presses RUN. Algorithm execution proceeds by first
    %         executing initialize on the first frame, followed by run on
    %         every frame, and terminate on the last frame.
    methods
        % a) Specify the initialize method to initialize the state of your
        %    algorithm. If your algorithm requires no initialization,
        %    remove this method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.initialize
        %
        %         function initialize(algObj, I)
        %
        %             disp('Executing initialize on the first image frame')
        %
        %             %--------------------------------------------------------------
        %             % Place your code here
        %             %--------------------------------------------------------------
        %
        %
        %
        %         end
        
        % b) Specify the run method to process an image frame and execute
        %    the algorithm. Algorithm execution begins at the first image
        %    frame and is invoked on all image frames selected for
        %    automation. Algorithm execution can produce a set of labels
        %    which are to be returned in autoLabels.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.run
        %
        function autoLabels = run(algObj, I)
            
            disp('Executing run on image frame')
            
            %--------------------------------------------------------------
            % Place your code here
            
            I = imadjust(I);
            imageInputSize = size(I); % [height width]
            
            % Threshold image - global threshold
            BW = imbinarize(I);
            
            % Open mask with disk
            radius = 5;
            decomposition = 0;
            se = strel('disk', radius, decomposition);
            BW = imopen(BW, se);
            
            % Create masked image.
            maskedImage = I;
            maskedImage(~BW) = 0;
            
            % Find circles
            [centers,radii,metric] = imfindcircles(maskedImage,algObj.radiusRange,'ObjectPolarity','bright','Sensitivity',algObj.Sensitivity);
            metric = rescale(metric); % Scaling the metric so that is is between 0 and 1.
            particles_boxes = [centers(:,1)-algObj.Mr.*radii, centers(:,2)-algObj.Mr.*radii, 2.*algObj.Mr.*radii, 2.*algObj.Mr.*radii];
            
            % Removing overlapping boxes
            distance = cell(length(centers),1);
            flag = zeros(length(centers),length(centers));
            
            for i = 1:1:length(centers)
                distance{i} = sqrt(sum((centers(i,:)-centers(:,:)).^2,2));
                flag(:,i) = distance{i} >0 & distance{i} <= algObj.nearness_factor*2*algObj.radiusRange(1);
            end
            flag_sum = sum(flag,2);
            particles_boxes(flag_sum>=1 & metric<algObj.metric_overlap_threshold,:) = [];
            metric(flag_sum>=1 & metric<algObj.metric_overlap_threshold,:) = [];
            
            
            % Remove those cricles whose boxes protrude out of the image
            index_remove = particles_boxes(:,1)<1 | particles_boxes(:,2)<1 | particles_boxes(:,1)+particles_boxes(:,3)>imageInputSize(2) | particles_boxes(:,2)+particles_boxes(:,4)>imageInputSize(1);
            particles_boxes(index_remove,:) = [];
            metric(index_remove,:) = [];
            
            autoLabels.Name     = algObj.SelectedLabelName;
            autoLabels.Type     = labelType.Rectangle;
            autoLabels.Position = particles_boxes;
            %--------------------------------------------------------------
            
            
            
        end
        
        % c) Specify the terminate method to clean up state of the executed
        %    algorithm. If your method requires no clean up, remove this
        %    method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.terminate
        %
        %         function terminate(algObj)
        %
        %             disp('Executing terminate')
        %
        %             %--------------------------------------------------------------
        %             % Place your code here
        %             %--------------------------------------------------------------
        %
        %
        %
        %         end
    end
    
end