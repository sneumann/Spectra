test_that(".initialize_h5peaks_file works", {
    if (!requireNamespace("rhdf5", quietly = TRUE))
        stop("Unable to load package rhdf5")
    tmpf <- tempfile()
    expect_true(.initialize_h5peaks_file(tmpf))
})

test_that(".valid_h5peaks_file works", {
    if (!requireNamespace("rhdf5", quietly = TRUE))
        stop("Unable to load package rhdf5")
    tmpf <- tempfile()
    expect_true(.initialize_h5peaks_file(tmpf))
    expect_null(.valid_h5peaks_file(tmpf))

    expect_true(file.remove(tmpf))
    h5 <- rhdf5::H5Fcreate(tmpf)
    rhdf5::h5createGroup(h5, "header")
    rhdf5::h5write("Something", h5, "/header/class")
    rhdf5::H5Fclose(h5)
    expect_true(is.character(.valid_h5peaks_file(tmpf)))

    expect_true(file.remove(tmpf))
    cat("something", file = tmpf)
    expect_true(is.character(.valid_h5peaks_file(tmpf)))
})

test_that(".valid_h5files works", {
    if (!requireNamespace("rhdf5", quietly = TRUE))
        stop("Unable to load package rhdf5")
    fls <- c("a", "a")
    expect_true(is.character(.valid_h5files(fls)))
    tmpa <- tempfile()
    tmpb <- tempfile()
    cat("dfd", file = tmpa)
    expect_true(.initialize_h5peaks_file(tmpb))

    expect_null(.valid_h5files(tmpb))
    expect_true(is.character(.valid_h5files(c(tmpa, tmpb))))
    expect_true(.initialize_h5peaks_file(tmpa))
    expect_null(.valid_h5files(c(tmpa, tmpb)))
})

test_that(".h5_read_bare works", {
    if (!requireNamespace("rhdf5", quietly = TRUE))
        stop("Unable to load package rhdf5")
    tmpf <- tempfile()
    h5 <- .initialize_h5peaks_file(tmpf)
    h5 <- .Call("_H5Fopen", tmpf, 0L, PACKAGE = "rhdf5")
    res <- .h5_read_bare(h5, "/header/class")
    expect_equal(res[[1]], "Spectra::MsBackendHdf5Peaks")
})

test_that(".hdf5_compression_level works", {
    orgn <- options()$HDF5_COMPRESSION_LEVEL
    expect_identical(.hdf5_compression_level(), orgn)
    options(HDF5_COMPRESSION_LEVEL = 5L)
    expect_identical(.hdf5_compression_level(), 5L)
    options(HDF5_COMPRESSION_LEVEL = orgn)
})

test_that(".h5_read_peaks, .h5_write_peaks works", {
    tmpf <- tempfile()
    expect_true(.initialize_h5peaks_file(tmpf))
    matlist <- list(cbind(mz = c(1.1, 1.2, 1.3, 1.4),
                          intensity = c(34, 2343, 321, 3)),
                    cbind(mz = c(2.1, 3, 4, 5, 6),
                          intensity = c(234, 433, 24, 3, 5)),
                    cbind(mz = c(1.2, 1.3),
                          intensity = c(23454, 343)))
    .h5_write_peaks(matlist, c(2L, 5L, 15L), h5file = tmpf, modCount = 0L)
    expect_error(res <- .h5_read_peaks(tmpf, scanIndex = 1L))
    res <- .h5_read_peaks(tmpf, scanIndex = 5L)
    expect_identical(res[[1]], matlist[[2]])

    res <- .h5_read_peaks(tmpf, scanIndex = c(2L, 5L, 15L))
    expect_identical(res, matlist)

    expect_error(.h5_read_peaks(tmpf, scanIndex = 5L, modCount = 2L),
                 "appear to have changed")

    .h5_write_peaks(matlist[2:3], scanIndex = 1:2, tmpf,
                    modCount = 2L)
    expect_error(.h5_read_peaks(tmpf, scanIndex = 1:2),
                 "appear to have changed")
    res <- .h5_read_peaks(tmpf, scanIndex = 2L, modCount = 2L)
    expect_identical(res, matlist[3])

    expect_true(is.list(.h5_read_peaks(tmpf)))

    tmp <- list(1:4, cbind(mz = c(1.4, 1.1, 1.4), intensity = 1:3),
                cbind(bla = c(1.1, 1.3), intensity = 1:2))
    expect_error(.h5_write_peaks(tmp, scanIndex = 1:3, tmpf, modCount = 0L),
                 "but I got integer")
    expect_error(.h5_write_peaks(tmp[2:3], scanIndex = 1:2, tmpf,
                                 modCount = 0L), "have to be ordered")
    expect_error(.h5_write_peaks(tmp[3], scanIndex = 2L, tmpf,
                                 modCount = 0L), "two columns")
})
