export function subset(array: Array<any>, size: number) {
  var result_set = [],
    result;

  for (var x = 0; x < Math.pow(2, array.length); x++) {
    result = [];
    let i = array.length - 1;
    do {
      if ((x & (1 << i)) !== 0) {
        result.push(array[i]);
      }
    } while (i--);

    if (result.length >= size) {
      result_set.push(result);
    }
  }

  return result_set;
}
