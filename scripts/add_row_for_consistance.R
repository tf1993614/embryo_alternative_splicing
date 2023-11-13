add_row_for_consistance = function(matrix_ls,
                                   target_data,
                                   collapse = F){
  row_count = map_int(matrix_ls, ~ nrow(.x))
  nrow = max(row_count)
  row_selector = unique(unlist(map(matrix_ls, ~ rownames(.x)))) 
  
  if(is.null(names(matrix_ls))){
    stop("matrix_ls should be named list")
  }
  
  res = map(
    names(matrix_ls),
    \(x){
      data = matrix_ls[[x]]
      column_selector = colnames(target_data)[str_detect(colnames(target_data), x)]
      data = data[, column_selector]
      fill_na = row_selector[! row_selector %in% rownames(data)]
      na_matrix = Matrix::Matrix(0, nrow = length(fill_na), ncol = ncol(data))
      rownames(na_matrix) = fill_na
      output = rbind(data, na_matrix)
      output = output %>% as.data.frame() %>% rownames_to_column("id")
    }
  )
  
  if(collapse){
    res = reduce(res, left_join, by = "id")
    res = res %>% column_to_rownames("id")
    return(Matrix::Matrix(as.matrix(res)))
  }
  else{
    res = res %>% column_to_rownames("id")
    return(Matrix::Matrix(as.matrix(res)))
  }
} 


