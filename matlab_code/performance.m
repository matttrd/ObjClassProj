function perf = performance(score)
% perf = PERFORMANCE(descr)
% restituisce l'indice di performance dei descrittori del sift
perf = sum(1./score(score ~= 0));
end