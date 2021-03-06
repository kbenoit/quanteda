test_that("corpus_subset works in a basic way", {
    corp <- corpus(corpus_subset(data_corpus_inaugural, Year > 1980 & Year < 2018))
    expect_equal(
        ndoc(corpus_subset(corp, Year > 2000)),
        5
    )
    expect_equal(
        length(levels(docid(corpus_subset(corp, Year > 2000, drop_docid = TRUE)))),
        5
    )
    expect_equal(
        length(levels(docid(corpus_subset(corp, Year > 2000, drop_docid = FALSE)))), 
        10
    )
    expect_equal(
        docnames(corpus_subset(corp, President == "Clinton")),
        c("1993-Clinton", "1997-Clinton")
    )
    expect_equal(
        docnames(corpus_subset(corp, c(TRUE, TRUE, rep(FALSE, 8)))),
        c("1981-Reagan", "1985-Reagan")
    )
    expect_warning(
        corpus_subset(corp, Year > 2000, something = 10),
        "something argument is not used.", fixed = TRUE
    )
})

test_that("head, tail.corpus work as expected", {
    corp <- corpus_subset(data_corpus_inaugural, Year < 2018)
    expect_equal(
        docnames(head(corp, 3)),
        c("1789-Washington", "1793-Washington", "1797-Adams")
    )
    expect_equal(
        docnames(head(corp, -55)),
        c("1789-Washington", "1793-Washington", "1797-Adams")
    )
    expect_equal(
        docnames(tail(corp, 3)),
        c("2009-Obama", "2013-Obama", "2017-Trump")
    )
    expect_equal(
        docnames(tail(corp, -55)),
        c("2009-Obama", "2013-Obama", "2017-Trump")
    )
})


test_that("corpus_subset works", {
    txt <- c(doc1 = "This is a sample text.\nIt has three lines.\nThe third line.",
             doc2 = "one\ntwo\tpart two\nthree\nfour.",
             doc3 = "A single sentence.",
             doc4 = "A sentence with \"escaped quotes\".")
    dat <- data.frame(var_numeric = 10:13, var_factor = factor(c("A", "B", "A", "B")), 
                      var_char = letters[1:4])
    
    corp <- corpus(txt, docvars = dat)
    expect_equal(ndoc(corpus_subset(corp, var_factor == "B")), 2)
    expect_equal(docnames(corpus_subset(corp, var_factor == "B")), 
                 c("doc2", "doc4"))
    
    corp_nodvar <- corpus(txt)
    expect_equal(ndoc(corpus_subset(corp_nodvar, LETTERS[1:4] == "B")), 1)
    expect_equal(docnames(corpus_subset(corp_nodvar, LETTERS[1:4] == "B")), 
                 c("doc2"))
    
})

