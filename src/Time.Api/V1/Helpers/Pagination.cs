using System;
using Microsoft.AspNetCore.Mvc;
using Time.Domain.Models;
using PaginationDetails = Time.Api.V1.Models.Pagination;

namespace Time.Api.V1.Helpers
{
    public static class Pagination
    {
        public static PaginationDetails GetPaginationDetails<T>(
            IUrlHelper urlHelper,
            Paged<T> pagedEntity,
            string actionName)
        {
            var previousPage = pagedEntity.PageNumber > 1
                ? urlHelper.Action(
                    actionName,
                    new
                    {
                        pageNumber = pagedEntity.PageNumber - 1,
                        pageSize = pagedEntity.PageSize
                    })
                : null;
            
            var nextPage = pagedEntity.PageNumber < pagedEntity.TotalPages
                ? urlHelper.Action(
                    actionName,
                    new
                    {
                        pageNumber = pagedEntity.PageNumber + 1,
                        pageSize = pagedEntity.PageSize
                    })
                : null;

            return new PaginationDetails
            {
                NextPage = nextPage,
                PreviousPage = previousPage,
                PageNumber = pagedEntity.PageNumber,
                PageSize = pagedEntity.PageSize,
                TotalItems = pagedEntity.TotalItems,
                TotalPages = pagedEntity.TotalPages
            };
        }
    }
}