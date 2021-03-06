#' Create a document-feature matrix
#'
#' Construct a sparse document-feature matrix, from a character, [corpus],
#' [tokens], or even other [dfm] object.
#' @param x a [tokens] or [dfm] object
#' @param tolower convert all features to lowercase
#' @param remove_padding logical; if `TRUE`, remove the "pads" left as empty tokens after
#' calling [tokens()] or [tokens_remove()] with `padding = TRUE`
#' @param verbose display messages if `TRUE`
#' @param ... not used directly
#' @section Changes in version 3:
#' In \pkg{quanteda} v3, many convenience functions formerly available in
#' `dfm()` were deprecated. Formerly, `dfm()` could be called directly on a
#' `character` or `corpus` object, but we now steer users to tokenise their
#' inputs first using [tokens()].  Other convenience arguments to `dfm()` were
#' also removed, such as `select`, `dictionary`, `thesaurus`, and `groups`.  All
#' of these functions are available elsewhere, e.g. through [dfm_group()].
#' See `news(Version >= "2.9", package = "quanteda")` for details.
#' @return a [dfm-class] object
#' @import Matrix
#' @export
#' @rdname dfm
#' @keywords dfm
#' @seealso  [dfm_select()], [dfm-class]
#' @examples
#' ## for a corpus
#' toks <- data_corpus_inaugural %>%
#'   corpus_subset(Year > 1980) %>%
#'   tokens()
#' dfm(toks)
#'
#' # removal options
#' toks <- tokens(c("a b c", "A B C D")) %>%
#'     tokens_remove("b", padding = TRUE)
#' toks
#' dfm(toks)
#' dfm(toks, remove = "") # remove "pads"
#'
#' # preserving case
#' dfm(toks, tolower = FALSE)
dfm <- function(x,
                tolower = TRUE,
                remove_padding = FALSE,
                verbose = quanteda_options("verbose"),
                ...) {
    dfm_env$START_TIME <- proc.time()
    object_class <- class(x)[1]
    if (verbose) message("Creating a dfm from a ", object_class, " input...")
    UseMethod("dfm")
}

#' @export
dfm.default <- function(x, ...) {
    check_class(class(x), "dfm")
}

# GLOBAL FOR dfm THAT FUNCTIONS CAN RESET AS NEEDED TO RECORD TIME ELAPSED
dfm_env <- new.env()
dfm_env$START_TIME <- NULL

#' @export
dfm.character <- function(x, ...) {
    .Deprecated(msg = "'dfm.character()' is deprecated. Use 'tokens()' first.")

    # deprecation for passing tokens arguments via ...
    otherargs <- list(...)
    otherargs_tokens <- otherargs[names(otherargs) %in% names(as.list(args(quanteda::tokens)))]
    if (length(otherargs_tokens[!which(names(otherargs_tokens) == "verbose")]))
        .Deprecated(msg = "'...' should not be used for tokens() arguments; use 'tokens()' first.")

    x <- do.call(tokens, c(list(x = x), otherargs_tokens))
    otherargs_tokens$verbose <- NULL
    do.call(dfm, c(list(x = x), otherargs[!names(otherargs) %in% names(otherargs_tokens)]))
}

#' @export
dfm.corpus <- function(x, ...) {
    .Deprecated(msg = "'dfm.corpus()' is deprecated. Use 'tokens()' first.")

    # deprecation for passing tokens arguments via ...
    otherargs <- list(...)
    otherargs_tokens <- otherargs[names(otherargs) %in% names(as.list(args(quanteda::tokens)))]
    if (length(otherargs_tokens[!which(names(otherargs_tokens) == "verbose")]))
        .Deprecated(msg = "'...' should not be used for tokens() arguments; use 'tokens()' first.")

    x <- do.call(tokens, c(list(x = x), otherargs_tokens))
    otherargs_tokens$verbose <- NULL
    do.call(dfm, c(list(x = x), otherargs[!names(otherargs) %in% names(otherargs_tokens)]))
}

#' @export
dfm.tokens <- function(x,
                       tolower = TRUE,
                       remove_padding = FALSE,
                       verbose = quanteda_options("verbose"),
                       ...) {
    # check for arguments passed to tokens via ...
    otherargs <- list(...)
    # if "remove" was matched to "remove_padding"
    if ("remove" %in% setdiff(names(as.list(sys.call())), names(as.list(match.call())))) {
        otherargs[["remove"]] <- remove_padding
        remove_padding <- FALSE
    }
    otherargs_tokens <- otherargs[names(otherargs) %in% names(as.list(args(quanteda::tokens)))]
    if (length(setdiff(names(otherargs_tokens), "verbose"))) {
        .Deprecated(msg = "'...' should not be used for tokens() arguments; use 'tokens()' first.")
        x <- do.call(tokens, c(list(x = x), otherargs_tokens))
        otherargs <- otherargs[!names(otherargs) %in% names(otherargs_tokens)]
    }

    if (tolower) {
        if (verbose) catm(" ...lowercasing\n", sep = "")
        x <- tokens_tolower(x)
        tolower <- FALSE
    }

    if (verbose) {
        catm(" ...found ",
             format(length(x), big.mark = ","), " document",
             # TODO: replace with: ntoken()
             ifelse(length(x) > 1, "s", ""),
             ", ",
             # TODO: replace with: ntype()
             format(length(types(x)), big.mark = ","),
             " feature",
             ifelse(length(types(x)) > 1, "s", ""),
             "\n", sep = "")
    }

    # deprecation for groups
    if ("groups" %in% names(otherargs)) {
        .Deprecated(msg = "'groups' is deprecated; use dfm_group() instead")
        if (verbose) catm(" ...grouping texts\n")
        x <- do.call(tokens_group, list(x = x, groups = otherargs[["groups"]], fill = FALSE))
        otherargs <- otherargs[-which(names(otherargs) == "groups")]
    }

    # fix to set valuetype and case_insensitive for dictionary/thesaurus, select/remove
    if (!is.null(otherargs[["valuetype"]]))
        warning("valuetype is deprecated in dfm()", call. = FALSE)
    valuetype <- match.arg(otherargs[["valuetype"]], c("glob", "regex", "fixed"))
    otherargs[["valuetype"]] <- NULL
    if (!is.null(otherargs[["case_insensitive"]]))
        warning("case_insensitive is deprecated in dfm()", call. = FALSE)
    case_insensitive <- otherargs[["case_insensitive"]]
    if (is.null(case_insensitive)) case_insensitive <- TRUE
    check_logical(case_insensitive)
    otherargs[["case_insensitive"]] <- NULL

    # deprecations for dictionary, thesaurus
    if (any(c("dictionary", "thesaurus") %in% names(otherargs))) {
        .Deprecated(msg = "'dictionary' and 'thesaurus' are deprecated; use dfm_lookup() instead")
        dictionary <- otherargs[["dictionary"]]
        thesaurus <- otherargs[["thesaurus"]]
        if (!is.null(thesaurus)) dictionary <- dictionary(thesaurus)
        if (verbose) catm(" ...")
        x <- do.call(tokens_lookup, list(x = x, dictionary = dictionary,
                                         exclusive = ifelse(!is.null(thesaurus), FALSE, TRUE),
                                         valuetype = valuetype,
                                         case_insensitive = case_insensitive,
                                         verbose = verbose))
        otherargs <- otherargs[-which(names(otherargs) %in% c("dictionary", "thesaurus"))]
    }

    # deprecation for select/remove
    if (any(c("select", "remove") %in% names(otherargs))) {
        select <- remove <- NULL
        if (!is.null(otherargs[["select"]]) && !is.null(otherargs[["remove"]]))
            stop("only one of select and remove may be supplied at once", call. = FALSE)
        if (!is.null(otherargs[["select"]])) {
            .Deprecated(msg = "'select' is deprecated; use dfm_select() instead")
            select <- otherargs[["select"]]
        }
        if (!is.null(otherargs[["remove"]])) {
            .Deprecated(msg = "'remove' is deprecated; use dfm_remove() instead")
            select <- otherargs[["remove"]]
        }
        if (verbose) catm(" ...")
        x <- do.call(tokens_select, 
                     list(x = x,
                          pattern = select,
                          selection = if (!is.null(otherargs[["select"]])) "keep" else "remove",
                          valuetype = valuetype,
                          case_insensitive = case_insensitive,
                          verbose = verbose))
        otherargs[["select"]] <- otherargs[["remove"]] <- NULL
    }

    if ("stem" %in% names(otherargs)) {
        if (!is.null(otherargs[["stem"]])) {
            stem <- otherargs[["stem"]]
            check_logical(stem)
            language <- quanteda_options("language_stemmer")
            if (verbose) catm(" ...stemming types (", stri_trans_totitle(language), ")\n", sep = "")
            x <- do.call(tokens_wordstem, list(x = x, language = language))
        }
        otherargs <- otherargs[-which(names(otherargs) %in% "stem")]
        .Deprecated(msg = "'stem' is deprecated; use dfm_wordstem() instead")
    }

    check_dots(otherargs, method = "dfm")

    remove_padding <- check_logical(remove_padding)
    if (remove_padding) {
        x <- tokens_remove(x, "", valuetype = "fixed")
    }
    
    # compile the dfm
    type <- types(x)
    attrs <- attributes(x)
    temp <- unclass(x)

    # shift index for padding, if any
    index <- unlist(temp, use.names = FALSE)
    if (attr(temp, "padding")) {
        type <- c("", type)
        index <- index + 1L
    }

    temp <-  sparseMatrix(j = index,
                          p = cumsum(c(1L, lengths(x))) - 1L,
                          x = 1L,
                          dims = c(length(x),
                                   length(type)))
    dfm.dfm(
        build_dfm(
            temp, type,
            docvars = get_docvars(x, user = TRUE, system = TRUE),
            meta = attrs[["meta"]]),
        tolower = FALSE, verbose = verbose
    )
}


#' @importFrom stringi stri_trans_totitle
#' @export
dfm.dfm <- function(x,
                    tolower = TRUE,
                    remove_padding = FALSE,
                    verbose = quanteda_options("verbose"),
                    ...) {
    x <- as.dfm(x)
    otherargs <- list(...)

    # if "remove" was matched to "remove_padding"
    if ("remove" %in% setdiff(names(as.list(sys.call())), names(as.list(match.call())))) {
        otherargs[["remove"]] <- remove_padding
        remove_padding <- FALSE
    }

    # deprecation for groups
    if ("groups" %in% names(otherargs)) {
        .Deprecated(msg = "'groups' is deprecated; use dfm_group() instead")
        if (verbose) catm(" ...grouping texts\n")
        x <- do.call(dfm_group, list(x = x, groups = otherargs[["groups"]], fill = FALSE))
        otherargs <- otherargs[-which(names(otherargs) == "groups")]
    }

    # fix to set valuetype and case_insensitive for dictionary/thesaurus, select/remove
    if (!is.null(otherargs[["valuetype"]]))
        warning("valuetype is deprecated in dfm()", call. = FALSE)
    valuetype <- match.arg(otherargs[["valuetype"]], c("glob", "regex", "fixed"))
    otherargs[["valuetype"]] <- NULL
    if (!is.null(otherargs[["case_insensitive"]]))
        warning("case_insensitive is deprecated in dfm()", call. = FALSE)
    case_insensitive <- otherargs[["case_insensitive"]]
    if (is.null(case_insensitive)) case_insensitive <- TRUE
    check_logical(case_insensitive)
    otherargs[["case_insensitive"]] <- NULL
    
    # deprecations for dictionary, thesaurus
    if (any(c("dictionary", "thesaurus") %in% names(otherargs))) {
        .Deprecated(msg = "'dictionary' and 'thesaurus' are deprecated; use dfm_lookup() instead")
        dictionary <- otherargs[["dictionary"]]
        thesaurus <- otherargs[["thesaurus"]]
        if (!is.null(thesaurus)) dictionary <- dictionary(thesaurus)
        if (verbose) catm(" ...")
        x <- do.call(dfm_lookup, list(x = x, dictionary = dictionary,
                           exclusive = ifelse(!is.null(thesaurus), FALSE, TRUE),
                           valuetype = valuetype,
                           case_insensitive = case_insensitive,
                           verbose = verbose))
        otherargs <- otherargs[-which(names(otherargs) %in% c("dictionary", "thesaurus"))]
    }

    # deprecation for select/remove
    if (any(c("select", "remove") %in% names(otherargs))) {
        select <- remove <- NULL
        if (!is.null(otherargs[["select"]]) && !is.null(otherargs[["remove"]]))
            stop("only one of select and remove may be supplied at once", call. = FALSE)
        if (!is.null(otherargs[["select"]])) {
            .Deprecated(msg = "'select' is deprecated; use dfm_select() instead")
            select <- otherargs[["select"]]
        }
        if (!is.null(otherargs[["remove"]])) {
            .Deprecated(msg = "'remove' is deprecated; use dfm_remove() instead")
            select <- otherargs[["remove"]]
        }
        if (verbose) catm(" ...")
        x <- do.call(dfm_select, 
                     list(x = x,
                          pattern = select,
                          selection = if (!is.null(otherargs[["select"]])) "keep" else "remove",
                          valuetype = valuetype,
                          case_insensitive = case_insensitive,
                          verbose = verbose))
        otherargs[["select"]] <- otherargs[["remove"]] <- NULL
    }

    if (tolower) {
        if (verbose) catm(" ...lowercasing\n", sep = "")
        x <- dfm_tolower(x)
    }

    if ("stem" %in% names(otherargs)) {
        if (!is.null(otherargs[["stem"]])) {
            stem <- otherargs[["stem"]]
            check_logical(stem)
            language <- quanteda_options("language_stemmer")
            if (verbose)
                if (verbose) catm(" ...stemming features (", stri_trans_totitle(language), ")\n", sep = "")
            x <- do.call(dfm_wordstem, list(x = x, language = language))
        }
        otherargs <- otherargs[-which(names(otherargs) %in% "stem")]
        .Deprecated(msg = "'stem' is deprecated; use dfm_wordstem() instead")
    }

    check_dots(otherargs, method = "dfm")

    remove_padding <- check_logical(remove_padding)
    if (remove_padding) {
        x <- dfm_remove(x, "", valuetype = "fixed")
    }

    # remove any NA named columns
    is_na <- is.na(featnames(x))
    if (any(is_na))
        x <- x[, !is_na, drop = FALSE]

    if (verbose) {
        catm(" ...complete, elapsed time:",
             format((proc.time() - dfm_env$START_TIME)[3], digits = 3), "seconds.\n")
        catm("Finished constructing a", paste(format(dim(x), big.mark = ",", trim = TRUE), collapse = " x "),
             "sparse dfm.\n")
    }

    return(x)
}


####
#### utility functions
####

## convert patterns (remove and select) to ngram regular expressions
# make_ngram_pattern <- function(features, valuetype, concatenator) {
#     if (valuetype == "glob") {
#         features <- stri_replace_all_regex(features, "\\*", ".*")
#         features <- stri_replace_all_regex(features, "\\?", ".{1}")
#     }
#     features <- paste0("(\\b|(\\w+", concatenator, ")+)",
#                        features, "(\\b|(", concatenator, "\\w+)+)")
#     features
# }

# create an empty dfm for given features and documents
make_null_dfm <- function(feature = NULL, document = NULL) {
    if (is.null(feature)) feature <- character()
    if (is.null(document)) document <- character()
    temp <- as(sparseMatrix(
        i = NULL,
        j = NULL,
        dims = c(length(document), length(feature))
    ), "dgCMatrix")

    build_dfm(temp, feature,
              docvars = make_docvars(length(document), document))
}

# pad dfm with zero-count features
pad_dfm <- function(x, feature) {
    feat_pad <- setdiff(feature, featnames(x))
    if (length(feat_pad)) {
        suppressWarnings(
            x <- cbind(x, make_null_dfm(feat_pad, docnames(x)))
        )
    }
    x <- x[, match(feature, featnames(x))]
    return(x)
}
