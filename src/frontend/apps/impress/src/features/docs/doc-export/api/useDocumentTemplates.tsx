import { APIList } from '@/api/types';
import {
  DefinedInitialDataInfiniteOptions,
  InfiniteData,
  QueryKey,
  useInfiniteQuery,
} from '@tanstack/react-query';
import { DocumentTemplates } from '..';
import { APIError, errorCauses, fetchAPI } from '@/api';

export enum DocumentTemplatesOrdering {
  TITLE = 'title',
  CREATED_AT = 'created_at',
}

export type DocumentTemplatesParams = {
  ordering: DocumentTemplatesOrdering;
};
type DocumentTemplatesAPIParams = DocumentTemplatesParams & {
  page: number;
};

type DocumentTemplatesResponse = APIList<DocumentTemplates>;

export const getDocumentTemplates = async ({
  ordering,
  page,
}: DocumentTemplatesAPIParams): Promise<DocumentTemplatesResponse> => {
  const orderingQuery = ordering ? `&ordering=${ordering}` : '';
  const response = await fetchAPI(
    `/api/v1.0/document-templates/?page=${page}${orderingQuery}`,
  );

  if (!response.ok) {
    throw new APIError(
      'Failed to get the templates',
      await errorCauses(response),
    );
  }

  return response.json() as Promise<DocumentTemplatesResponse>;
};

export const KEY_LIST_TEMPLATE = 'templates';

export function useTemplates(
  param: DocumentTemplatesParams,
  queryConfig?: DefinedInitialDataInfiniteOptions<
    DocumentTemplatesResponse,
    APIError,
    InfiniteData<DocumentTemplatesResponse>,
    QueryKey,
    number
  >,
) {
  return useInfiniteQuery<
    DocumentTemplatesResponse,
    APIError,
    InfiniteData<DocumentTemplatesResponse>,
    QueryKey,
    number
  >({
    initialPageParam: 1,
    queryKey: [KEY_LIST_TEMPLATE, param],
    queryFn: ({ pageParam }) =>
      getDocumentTemplates({
        ...param,
        page: pageParam,
      }),
    getNextPageParam(lastPage, allPages) {
      return lastPage.next ? allPages.length + 1 : undefined;
    },
    ...queryConfig,
  });
}
