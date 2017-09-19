global blobTest
if (blobTest(k).counter(1) == blobTest(k).counter(2))
    if (blobTest(k).type == 1)
        blobTest(k).color = [0 0.5 0];
        blobTest(k).className = ['Persona '];
    else
        blobTest(k).color = [1 0 0];
        blobTest(k).className = ['Macchina '];
    end
else
    if (blobTest(k).counter(1) > blobTest(k).counter(2))
        blobTest(k).color = [0 0.5 0];
        blobTest(k).className = ['Persona '];
        blobTest(k).type = 1;
    else
        blobTest(k).color = [1 0 0];
        blobTest(k).className = ['Macchina '];
        blobTest(k).type = 2;
    end
end