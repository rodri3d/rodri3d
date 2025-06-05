clear

% Script para análisis mensual de perfiles verticales promedio (sph)
% Dataset: COSMIC1 y COSMIC2 combinados
% Objetivo: calcular perfiles verticales medios mensuales por año
% Datos fuente: archivos vp_YYYY_JJJ.mat (COSMIC1) y sph_YYYY_JJJ.mat (COSMIC2)
% Resultado: matriz sph_mensual (niveles × años × meses)

% --- Inicializar ---
ruta1 = 'D:\RO_nuevos\cosmic1';
ruta2 = 'D:\RO_nuevos\cosmic2\datos';
anios = 2007:2023;
meses = 1:12;
niveles = [];
sph_mensual_temp = {};  % será redimensionada dinámicamente

% --- Loop por año y mes ---
for a = 1:length(anios)
    anio = anios(a);
    for m = meses
        jdays = datenum(anio, m+1, 1) - datenum(anio, m, 1);  % cantidad de días del mes
        perfiles_mes = [];

        for d = 1:jdays
            jday = datenum(anio, m, d) - datenum(anio,1,0);  % juliano
            nombre_cosmic1 = sprintf('vp_%d_%03d.mat', anio, jday);
            nombre_cosmic2 = sprintf('sph_%d_%03d.mat', anio, jday);
            usado = false;

            usar_cosmic1 = true;
            usar_cosmic2 = true;
            if anio == 2007
                usar_cosmic2 = false;  % solo usar cosmic1 en 2007
            elseif anio < 2019 || (anio == 2019 && jday < 334)
                usar_cosmic2 = false;  % cosmic2 solo desde jday 334 de 2019
            end

            fpath1 = fullfile(ruta1, nombre_cosmic1);
            fpath2 = fullfile(ruta2, nombre_cosmic2);

            if d == 1 && m == 1 && a == 1
                fprintf('Probando archivo: %s\nRuta1: %s\nRuta2: %s\n', nombre_cosmic1, fpath1, fpath2);
            end

            % --- Intentar primero con COSMIC1 si corresponde ---
            if usar_cosmic1
                if exist(fpath1, 'file')
                    data = load(fpath1);
                    if isfield(data, 'sph')
                        matriz = data.sph;
                    elseif isfield(data, 'vp') && isfield(data, 'p')
                        vp = data.vp;
                        p = data.p;
                        matriz = [data.lat; data.lon; 0.622 .* vp ./ (p - 0.378 .* vp)];
                    else
                        matriz = [];
                    end

                    if ~isempty(matriz) && size(matriz,1) >= 3
                        if isempty(niveles) || size(matriz,1)-2 > niveles
                            niveles = size(matriz,1) - 2;
                        end
                        perfiles = matriz(3:end, :);
                        perfiles_mes = [perfiles_mes, perfiles];
                        usado = true;
                    end
                end
            end

            % --- Intentar con COSMIC2 solo si corresponde y no se usó COSMIC1 ---
            if usar_cosmic2 && ~usado
                if exist(fpath2, 'file')
                    data = load(fpath2);
                    if isfield(data, 'sph')
                        matriz = data.sph;
                        if size(matriz,1) >= 3
                            if isempty(niveles) || size(matriz,1)-2 > niveles
                                niveles = size(matriz,1) - 2;
                            end
                            perfiles = matriz(3:end, :);
                            perfiles_mes = [perfiles_mes, perfiles];
                        end
                    end
                end
            end
        end

        if ~isempty(perfiles_mes)
            sph_mensual_temp{a, m} = perfiles_mes;
            fprintf('Registrado mes %d, año %d ? perfiles: %d\n', m, anio, size(perfiles_mes,2));
            fprintf('Dimensiones actuales de sph_mensual_temp: %dx%d\n', size(sph_mensual_temp,1), size(sph_mensual_temp,2));
        end
    end
end

% --- Consolidar perfiles promedio ---
sph_mensual = NaN(niveles, length(anios), length(meses));
for a = 1:length(anios)
    for m = 1:length(meses)
        perfiles = sph_mensual_temp{a, m};
        if ~isempty(perfiles)
            sph_mensual(:, a, m) = mean(perfiles, 2, 'omitnan');
        end
    end
end

% --- Guardar resultado ---
save('sph_promedios_mensuales.mat', 'sph_mensual', 'anios', 'meses')
