clear;
clc;
close all;

mkdir('./graphs'); % will generate a harmless warning if directory already exists

% can't use strings here, gotta do these weird literals? (Bare words, in other languages. Really weird)
load data/28V_200mA_10DegC_Aluminum.txt; % -> variable named X28V_200mA_10DegC_Aluminum
load data/30V_280mA_10DegC_Aluminum.txt;
load data/30V_280mA_10DegC_Brass.txt;
load data/30V_300mA_10DegC_Steel.txt;

% keep these two in the same order, lest you wreak havok
data_sets = { X28V_200mA_10DegC_Aluminum ...
              X30V_280mA_10DegC_Aluminum ...
              X30V_280mA_10DegC_Brass    ...
              X30V_300mA_10DegC_Steel };
data_names = { '5.6W Aluminum' ...
               '8.4W Aluminum' ...
               '8.4W Brass'    ...
               '9W Steel' };
alphas = [ 4.82*10^-5, ... % thermal diffusivities
           4.82*10^-5, ...
           3.56*10^-5, ...
           4.12*10^-6 ];

T0 = 10; % degrees C

for i = 1:length(data_sets)
  data  = data_sets{i};
  name  = data_names{i};
  alpha = alphas(i);
  x     = 2.54.*[1:0.5:4.5]; % locations of the thermocouples (cm)

  % Time (sec)	TC 1 - Near Chiller	TC 2	TC 3	TC 4	TC 5	TC 6	TC 7	TC 8 - Near Heater
  t = data(end, 1);
  tc = data(end, 2:end);

  % Linear fit for steady state condition
  p  = polyfit(x, tc, 1);
  m  = p(1);
  b  = p(2);
  x0 = (T0 - b)/m; % cm
  x = x - x0; % offset by x0
  H = m*100; % convert to degC / m
  L = max(x)/100; % convert to meters

  fprintf('%s: H = %.2f deg C/m, %.2f cm to first thermocouple\n', name, H, x(1));

  % analyitical vs experimental steady state
  figure; hold on; grid on;
  b      = @(n) 8*H*L./(((2*n - 1)^2) * pi^2 )*(-1)^n;
  lambda = @(n) pi*(2*n - 1)/(2*L);
  xrange = linspace(0, L, 100);
  temps  = u(xrange, t, b, lambda, alpha, H, T0, 10); % 10 forier terms
  plot(xrange*100, temps, ...
        'DisplayName', 'analyitical steady-state', 'linewidth', 2);
  plot(x, tc, ...
        'DisplayName', 'experimental steady-state');
  scatter(x, tc, 'r*', ...
        'DisplayName', 'thermocouples');
  title(name)
  xlabel('Distance from X0');
  ylabel('Temperature (C)');
  legend('show', 'location', 'southeast')
  print(['graphs/', name], '-dpng')

  % each thermocouple over time
  t = data(:, 1);
  tc = data(:, 2:end);
  figure; hold on; grid on;
  for thermocouple = 1:8
    xt = x(thermocouple);
    plot(t, tc(:, thermocouple), 'r');
    plot(t, u(xt/100, t, b, lambda, alpha, H, T0, 10), 'b')
  end
  title(sprintf('%s: red = experimental, blue = analyitical', name));
  xlabel('Time (seconds)');
  ylabel('Temperature (C)');
  print(['graphs/', name, ' thermocouples'], '-dpng');

  % find temperature unevenness at the beginning of the experiment
  p = polyfit(x, tc(1, :), 1);
  fprintf('    %.2f deg C / cm at initial time\n', p(1));

end
