classdef diagmat
    % Class for a sparse representation of a diagonal matrix,
	% that is compatible with single as well as double.
	%   - Damien Loterie (09/2014
    
    properties
        x;
        dims;
        ind;
    end
    
    methods
        function obj = diagmat(x, dims)
            % Checks
            if sum(size(x)>1)>1
                error('Input must be a vector.');
            end
            if numel(dims)~=2
                error('Dimensions must be a vector with two elements.'); 
            end
            if numel(x)~=min(dims)
                error('There must be as many diagonal elements as the smallest dimension.');
            end
            
            % Store
            obj.x = reshape(x,[numel(x) 1]);
            obj.dims = dims;
            obj.ind = sub2ind(dims,1:numel(x),1:numel(x)).';
        end
        
        % Expand
        function A = full(a)
            A = zeros(a.dims,'like',a.x);
            A(a.ind) = a.x;
        end
        
        % Display
        function disp(a)
            display(full(a));
        end
        
        % Addition
        function c = plus(a,b)
            % Cases
            if isa(a,'diagmat')
                if isa(b,'diagmat')
                    % Check
                    if ~all(a.dims==b.dims)
                       error('Dimensions do not match'); 
                    end
                    
                    % Calculate
                    c = a;
                    c.x = a.x + b.x;
                else
                    % Check
                    if ~all(a.dims==size(b))
                       error('Dimensions do not match'); 
                    end
                    
                    % Calculate
                    c = b;
                    c(a.ind) = c(a.ind) + a.x;
                end
            else
                % Check
                if ~all(size(a)==b.dims)
                   error('Dimensions do not match'); 
                end
                
                % Calculate 
                c = a;
                c(b.ind) = c(b.ind) + b.x;
            end
        end
        
        % Matrix multiplication
        function c = mtimes(a,b)
            % Cases
            if isa(a,'diagmat')
                if isa(b,'diagmat')
                    % Check
                    if a.dims(2)~=b.dims(1)
                       error('Inner matrix dimensions must agree.'); 
                    end
                    
                    % New dimensions
                    new_dims = [a.dims(1) b.dims(2)];
                    num_nonzero = min(numel(a.x), numel(b.x));
                    num_zero    = min(new_dims)-num_nonzero;
                    
                    % Calculate
                    c = diagmat(cat(1,a.x(1:num_nonzero).*b.x(1:num_nonzero),zeros(num_zero,1,'like',a.x)), new_dims);
                else
                    % Check
                    if a.dims(2)~=size(b,1)
                       error('Inner matrix dimensions must agree.'); 
                    end
                    
                    % New dimensions
                    new_dims = [a.dims(1) size(b,2)];
                    rows = min(a.dims(1),size(b,1));
                    
                    % Calculate
                    c = zeros(new_dims,'like',b);
                    c(1:rows,:) = bsxfun(@times, a.x, b(1:rows,:));

                end
            else
                    % Check
                    if size(a,2)~=b.dims(1);
                       error('Inner matrix dimensions must agree.'); 
                    end
                    
                    % New dimensions
                    new_dims = [size(a,1) b.dims(2)];
                    cols = min(size(a,2),b.dims(2));
                    
                    % Calculate
                    c = zeros(new_dims,'like',a);
                    c(:,1:cols) = bsxfun(@times, a(:,1:cols), b.x.');
            end
        end
    end
    
    methods (Static)
        function test()
            n = randperm(10);
            
            % Generate random diagonal matrix
            randdiagmat = @(dims)diagmat(randi(10,[min(dims) 1]),dims);
            randmat     = @(dims)randi(10,dims);
            
            % Addition
            n_add = [n(1) n(2)];
            n_add_min = min(n_add);
            A = randdiagmat(n_add);
            B = randdiagmat(n_add);
            C = randmat(n_add);
            
            if sum(sum(abs(full(A+B)-(full(A)+full(B)))))~=0
               error('Incorrect addition (diagmat/diagmat)'); 
            end
            if sum(sum(abs(full(A+C)-(full(A)+C))))~=0
               error('Incorrect addition (diagmat/matrix)'); 
            end
            if sum(sum(abs(full(C+B)-(C+full(B)))))~=0
               error('Incorrect addition (matrix/diagmat)'); 
            end
            
            % Multiplication
            n_mul1 = [n(1) n(2)];
            n_mul2 = [n(2) n(3)];
            A1 = randdiagmat(n_mul1);
            A2 = randdiagmat(n_mul2);
            B1 = randmat(n_mul1);
            B2 = randmat(n_mul2);
            
            if sum(sum(abs(full(A1*A2)-(full(A1)*full(A2)))))~=0
               error('Incorrect multiplication (diagmat/diagmat)'); 
            end
            if sum(sum(abs(full(A1*B2)-(full(A1)*B2))))~=0
               error('Incorrect multiplication (diagmat/matrix)'); 
            end
            if sum(sum(abs(full(B1*A2)-(B1*full(A2)))))~=0
               error('Incorrect multiplication (matrix/diagmat)'); 
            end
            
        end
    end
    
end

