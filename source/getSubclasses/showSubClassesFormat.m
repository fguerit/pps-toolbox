function showSubClassesFormat()
% showSubClassesFormat draws all the classes currently implemented, that are
% related to the Format class

getSubclasses('Format','source')
title('Subclasses of "Format" implemented')