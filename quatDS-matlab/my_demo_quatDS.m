%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   Define att/init positions and quaternion  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%% Toy Attractors and Init poses %%%%%
clear all; close all; clc;
% Attractor
att_pos = [0.5,0.25,0]';
roll = -0.015; pitch = 0.001; yaw= 3.13535;
att_R = eul2rotm([yaw,pitch,roll]');
att_quat = my_quaternion(att_R);

% Initial configurations
% x0_all = [[0,0,0.5]' [0.5,0,0.5]'  [1,0,0.5]'  [-0.4486, 0.3119, 0.43699]'];
roll_1 = -1.5; pitch_1 = 1.5; yaw_1= 2.13535;
roll_2 =  2.5; pitch_2 = -1.5; yaw_2= -2.13535;
quat0_all = [[1,0,0,0]' my_quaternion(eul2rotm([yaw_1,pitch_1,roll_1]')) my_quaternion(eul2rotm([yaw_2,pitch_2,roll_2]')) [0.69736, -0.0454,-0.713,0.05638]' ];


%% %%% Real Robot Attractors and Init poses %%%%%
clear all; close all; clc;
% Attractor
att_pos = [-0.419, -0.0468, 0.15059]';
att_quat = [-0.04616,-0.124,0.991007,-0.018758]';
att_R =  my_quaternion(att_quat);

% From real robot simulation
x0_all = [[-0.398287790221, 0.276403682489, 0.40357671952]' [-0.3687019795, -0.31078379649, 0.353700792986]' [-0.674814265398, 0.214883445878, 0.614376695163]'];
quat0_all = [[0.590064946744, 0.679998360383, -0.300609096301, -0.314737604554]' [0.711304, -0.021037765273, -0.702077440469, -0.0262812481386]' [0.746608, 0.563370280825, -0.201834619809, -0.290607963541]'];

%% %%% Visualize target and init %%%%%%
figure('Color',[1 1 1]);

% Draw World Reference Frame
% drawframe(eye(4),0.025); hold on;

% Draw World Reference Frame
H = zeros(4,4,1+size(x0_all,2)    );
H(1:3,1:3,1) = att_R;
H(1:3,4,1)   = att_pos;
H(1:3,1:3,2:end) = my_quaternion(quat0_all);
H(1:3,4,2:end)   = x0_all;

for i=1:1+size(x0_all,2)-1    
    % Draw Frame
    drawframe(H(:,:,i),0.075); hold on;    
end
text(att_pos(1),att_pos(2),att_pos(3),'$x^*,q^*$','FontSize',20,'Interpreter','LaTex');
grid on;
axis equal;
xlabel('x','Interpreter','LaTex');
ylabel('y','Interpreter','LaTex');
zlabel('z','Interpreter','LaTex');
view([-117 12])

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    Define linear DS for position and quaternion   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Select initial pose
init = 2;

% Position S parameters
A_pos = 0.5*diag([-1;-2;-3]);
ds_pos = @(x) linear_ds(x,att_pos,A_pos);

% Quaternion DS parameters
A_quat = -1.5*eye(3);
ds_quat = @(q) linear_quat_ds(q,att_quat,A_quat);

% Initial values/simulation parameters
dt = 0.075; iter = 1; 
Max_iter = 500;
x_sim = []; x_curr = x0_all(:,init);
q_sim = []; q_curr = quat0_all(:,init);
pos_error = []; quat_error = [];

% Simulation loop
while iter < Max_iter
    
    % Position Dynamics
    xdot = ds_pos(x_curr);    
    x_curr = x_curr + xdot*dt;
    x_sim = [x_sim x_curr];
    pos_error = [pos_error norm(x_curr-att_pos)];    
    
    % Orientation Dynamics
    omega = ds_quat(q_curr);
    q_curr = quat_multiply(quat_exponential(omega, dt)',q_curr')';
    quat_sim = [q_sim q_curr];
    quat_error = [quat_error quat_dist(q_curr,att_quat)];
    
    % Stopping criteria    
    pos_err  = pos_error(iter)
    quat_err =  quat_error(iter)
    if pos_err < 0.0025 && quat_err < 0.05       
        iter
        break;
    end
    iter = iter + 1;
    
    % Draw Rigid Body Frame
    H_curr = zeros(4,4);
    H_curr(1:3,1:3) = my_quaternion(q_curr);
    H_curr(1:3,4)   = x_curr;
    drawframe(H_curr,0.075); hold on;    
    drawnow
end

%% Convergence plots
figure('Color',[1 1 1]);
plot(pos_error,'r*'); hold on;
plot(quat_error,'b*'); hold on;
grid on;
legend('||x-x^*||','||log(q,q^*)||');
xlabel('Time-step', 'Interpreter','LaTex');
ylabel('Position', 'Interpreter','LaTex');
title('Convergence of Position + Orientation Dynamics', 'Interpreter','LaTex')



